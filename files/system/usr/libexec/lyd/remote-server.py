#!/usr/bin/python3
"""LAN touch remote for Lyd HTPC. Pairing tokens are stored locally."""
import json, os, secrets, time, subprocess, html
from pathlib import Path
from aiohttp import web
from evdev import UInput, ecodes as e

STATE=Path("/var/lib/lyd-remote")
TOKENS=STATE/"paired.json"
PENDING=STATE/"pending.json"
STATE.mkdir(parents=True,exist_ok=True)
os.chmod(STATE,0o700)
ui=UInput(name="Lyd HTPC Web Remote",events={
 e.EV_KEY:[e.BTN_LEFT,e.BTN_RIGHT,e.KEY_ESC,e.KEY_HOME,e.KEY_LEFTMETA,e.KEY_TAB,
 e.KEY_ENTER,e.KEY_BACKSPACE,e.KEY_SPACE,e.KEY_UP,e.KEY_DOWN,e.KEY_LEFT,e.KEY_RIGHT,
 *[getattr(e,"KEY_"+chr(65+i)) for i in range(26)],
 *[getattr(e,"KEY_"+str(i)) for i in range(10)],e.KEY_DOT,e.KEY_COMMA,e.KEY_MINUS,e.KEY_SLASH],
 e.EV_REL:[e.REL_X,e.REL_Y]})
def read(path,default):
 try:return json.loads(path.read_text())
 except (OSError,ValueError):return default
def write(path,data):
 tmp=path.with_suffix(".tmp");tmp.write_text(json.dumps(data));os.chmod(tmp,0o600);tmp.replace(path)
def key(code,down=True):ui.write(e.EV_KEY,code,int(down));ui.syn()
def tap(code):key(code);key(code,False)
def auth(req):
 token=req.headers.get("Authorization","").removeprefix("Bearer ").strip()
 return any(secrets.compare_digest(token,x.get("token","")) for x in read(TOKENS,[]))
async def index(_):return web.FileResponse("/usr/share/lyd-remote/index.html")
async def tv(_):return web.FileResponse("/usr/share/lyd-remote/tv.html")
async def pair_start(req):
 code=secrets.token_urlsafe(24)
 host=req.headers.get("Host","localhost:8765")
 write(PENDING,{"code":code,"url":f"http://{host}/pair?code={code}","expires":time.time()+180})
 return web.json_response({"expires_in":180,"message":"Scan the QR code shown on the TV"})
async def pending(_):
 p=read(PENDING,{})
 if time.time()>p.get("expires",0):return web.json_response({"active":False})
 return web.json_response({"active":True})
async def qr(_):
 p=read(PENDING,{})
 if time.time()>p.get("expires",0):raise web.HTTPNotFound()
 try:
  svg=subprocess.run(["qrencode","-t","SVG","-o","-","-m","2",p["url"]],check=True,capture_output=True).stdout
 except (OSError,subprocess.CalledProcessError):raise web.HTTPServiceUnavailable(text="QR generator unavailable")
 return web.Response(body=svg,content_type="image/svg+xml")
async def pair_finish(code,name):
 p=read(PENDING,{})
 if time.time()>p.get("expires",0) or not secrets.compare_digest(str(code),p.get("code","")):
  raise web.HTTPForbidden(text="Pairing code expired or invalid")
 token=secrets.token_urlsafe(32)
 devices=read(TOKENS,[]);devices.append({"name":str(name)[:40],"token":token,"created":int(time.time())})
 write(TOKENS,devices);PENDING.unlink(missing_ok=True)
 return token
async def pair_link(req):
 token=await pair_finish(req.query.get("code",""),"Phone remote")
 page="""<!doctype html><meta name=viewport content='width=device-width'><title>Remote paired</title>
 <body style='font:20px system-ui;background:#17191f;color:white;text-align:center;padding:15vh 8px'>
 <h1>Remote paired</h1><p>This phone can now control the HTPC.</p><script>
 localStorage.setItem('lyd-token',TOKEN);location.replace('/');
 </script></body>""".replace("TOKEN",json.dumps(token))
 return web.Response(text=page,content_type="text/html")
async def control(req):
 if not auth(req):raise web.HTTPUnauthorized()
 d=await req.json();a=d.get("action")
 if a=="move":
  ui.write(e.EV_REL,e.REL_X,max(-120,min(120,int(d.get("dx",0)))))
  ui.write(e.EV_REL,e.REL_Y,max(-120,min(120,int(d.get("dy",0)))));ui.syn()
 elif a=="click":tap(e.BTN_LEFT)
 elif a=="right":tap(e.BTN_RIGHT)
 elif a=="back":tap(e.KEY_ESC)
 elif a=="home":tap(e.KEY_HOME)
 elif a=="apps":key(e.KEY_LEFTMETA);tap(e.KEY_TAB);key(e.KEY_LEFTMETA,False)
 elif a=="keyboard":pass
 else:raise web.HTTPBadRequest(text="Unknown action")
 return web.json_response({"ok":True})
async def text_input(req):
 if not auth(req):raise web.HTTPUnauthorized()
 text=str((await req.json()).get("text",""))[:256]
 mapping={chr(97+i):getattr(e,"KEY_"+chr(65+i)) for i in range(26)}
 mapping.update({str(i):getattr(e,"KEY_"+str(i)) for i in range(10)})
 mapping.update({" ":"KEY_SPACE",".":"KEY_DOT",",":"KEY_COMMA","-":"KEY_MINUS","/":"KEY_SLASH","\n":"KEY_ENTER"})
 for ch in text:
  code=mapping.get(ch.lower())
  if code is None:continue
  if ch.isupper():key(e.KEY_LEFTSHIFT)
  tap(code)
  if ch.isupper():key(e.KEY_LEFTSHIFT,False)
 return web.json_response({"ok":True})
async def devices(req):
 if not auth(req):raise web.HTTPUnauthorized()
 return web.json_response([{"name":d["name"],"created":d["created"]} for d in read(TOKENS,[])])
async def unpair(req):
 if not auth(req):raise web.HTTPUnauthorized()
 token=req.headers.get("Authorization","").removeprefix("Bearer ").strip()
 write(TOKENS,[d for d in read(TOKENS,[]) if not secrets.compare_digest(token,d.get("token",""))])
 return web.json_response({"ok":True})
app=web.Application(client_max_size=4096)
app.add_routes([web.get("/",index),web.get("/tv",tv),web.get("/pair",pair_link),
 web.post("/api/pair/start",pair_start),web.get("/api/pair/pending",pending),web.get("/api/pair/qr",qr),
 web.post("/api/control",control),web.post("/api/text",text_input),web.get("/api/devices",devices),
 web.delete("/api/device",unpair)])
web.run_app(app,host="0.0.0.0",port=8765)
