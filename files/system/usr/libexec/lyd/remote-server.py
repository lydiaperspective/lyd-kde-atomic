#!/usr/bin/python3
"""LAN touch remote for Lyd HTPC. Pairing tokens are stored locally."""
import json, os, secrets, time
from pathlib import Path
from aiohttp import web
from evdev import UInput, ecodes as e

STATE = Path("/var/lib/lyd-remote")
TOKENS = STATE / "paired.json"
PENDING = STATE / "pending.json"
STATE.mkdir(parents=True, exist_ok=True)
os.chmod(STATE, 0o700)

ui = UInput(name="Lyd HTPC Web Remote", events={
    e.EV_KEY: [e.BTN_LEFT, e.BTN_RIGHT, e.KEY_ESC, e.KEY_HOME,
               e.KEY_LEFTMETA, e.KEY_TAB, e.KEY_ENTER, e.KEY_BACKSPACE,
               e.KEY_SPACE, e.KEY_UP, e.KEY_DOWN, e.KEY_LEFT, e.KEY_RIGHT,
               e.KEY_A, e.KEY_B, e.KEY_C, e.KEY_D, e.KEY_E, e.KEY_F,
               e.KEY_G, e.KEY_H, e.KEY_I, e.KEY_J, e.KEY_K, e.KEY_L,
               e.KEY_M, e.KEY_N, e.KEY_O, e.KEY_P, e.KEY_Q, e.KEY_R,
               e.KEY_S, e.KEY_T, e.KEY_U, e.KEY_V, e.KEY_W, e.KEY_X,
               e.KEY_Y, e.KEY_Z, e.KEY_0, e.KEY_1, e.KEY_2, e.KEY_3,
               e.KEY_4, e.KEY_5, e.KEY_6, e.KEY_7, e.KEY_8, e.KEY_9,
               e.KEY_DOT, e.KEY_COMMA, e.KEY_MINUS, e.KEY_SLASH],
    e.EV_REL: [e.REL_X, e.REL_Y],
})

def read_json(path, default):
    try: return json.loads(path.read_text())
    except (OSError, ValueError): return default

def write_json(path, value):
    tmp=path.with_suffix(".tmp")
    tmp.write_text(json.dumps(value))
    os.chmod(tmp, 0o600)
    tmp.replace(path)

def key(code, pressed=True):
    ui.write(e.EV_KEY, code, 1 if pressed else 0); ui.syn()

def tap(code):
    key(code, True); key(code, False)

def authorized(request):
    token=request.headers.get("Authorization", "").removeprefix("Bearer ").strip()
    return any(secrets.compare_digest(token, item.get("token",""))
               for item in read_json(TOKENS, []))

async def index(_):
    return web.FileResponse("/usr/share/lyd-remote/index.html")

async def tv(_):
    return web.FileResponse("/usr/share/lyd-remote/tv.html")

async def pair_start(_):
    code=secrets.token_urlsafe(24)
    write_json(PENDING, {"code":code,"expires":time.time()+180})
    return web.json_response({"code":code,"expires_in":180})

async def pair_finish(request):
    data=await request.json()
    pending=read_json(PENDING,{})
    if time.time()>pending.get("expires",0) or not secrets.compare_digest(str(data.get("code","")),pending.get("code","")):
        raise web.HTTPForbidden(text="Pairing code expired or invalid")
    name=str(data.get("name","Phone remote"))[:40]
    token=secrets.token_urlsafe(32)
    devices=read_json(TOKENS,[])
    devices.append({"name":name,"token":token,"created":int(time.time())})
    write_json(TOKENS,devices)
    PENDING.unlink(missing_ok=True)
    return web.json_response({"token":token,"name":name})

async def control(request):
    if not authorized(request): raise web.HTTPUnauthorized()
    data=await request.json()
    action=data.get("action")
    if action=="move":
        dx=max(-120,min(120,int(data.get("dx",0))))
        dy=max(-120,min(120,int(data.get("dy",0))))
        ui.write(e.EV_REL,e.REL_X,dx); ui.write(e.EV_REL,e.REL_Y,dy); ui.syn()
    elif action=="click": tap(e.BTN_LEFT)
    elif action=="right": tap(e.BTN_RIGHT)
    elif action=="back": tap(e.KEY_ESC)
    elif action=="home": tap(e.KEY_HOME)
    elif action=="apps":
        key(e.KEY_LEFTMETA); tap(e.KEY_TAB); key(e.KEY_LEFTMETA,False)
    elif action=="keyboard":
        # Phone keyboard text is sent through /api/text; this action focuses
        # the remote's text-entry field rather than toggling a host OSK.
        pass
    else: raise web.HTTPBadRequest(text="Unknown action")
    return web.json_response({"ok":True})

async def text_input(request):
    if not authorized(request): raise web.HTTPUnauthorized()
    data=await request.json()
    text=str(data.get("text",""))[:256]
    mapping={**{chr(97+i):getattr(e,"KEY_"+chr(65+i)) for i in range(26)},
             **{str(i):getattr(e,"KEY_"+str(i)) for i in range(10)},
             " ":"KEY_SPACE",".":"KEY_DOT",",":"KEY_COMMA","-":"KEY_MINUS",
             "/":"KEY_SLASH","\n":"KEY_ENTER"}
    for ch in text:
        code_name=mapping.get(ch.lower())
        if not code_name: continue
        code=getattr(e,code_name)
        if ch.isupper(): key(e.KEY_LEFTSHIFT)
        tap(code)
        if ch.isupper(): key(e.KEY_LEFTSHIFT,False)
    return web.json_response({"ok":True})

async def devices(request):
    if not authorized(request): raise web.HTTPUnauthorized()
    return web.json_response([{"name":d["name"],"created":d["created"]} for d in read_json(TOKENS,[])])

async def unpair(request):
    if not authorized(request): raise web.HTTPUnauthorized()
    token=request.headers.get("Authorization","").removeprefix("Bearer ").strip()
    write_json(TOKENS,[d for d in read_json(TOKENS,[]) if not secrets.compare_digest(token,d.get("token",""))])
    return web.json_response({"ok":True})

app=web.Application(client_max_size=4096)
app.add_routes([
 web.get("/",index), web.get("/tv",tv),
 web.post("/api/pair/start",pair_start), web.post("/api/pair/finish",pair_finish),
 web.post("/api/control",control), web.post("/api/text",text_input),
 web.get("/api/devices",devices), web.delete("/api/device",unpair)
])
web.run_app(app,host="0.0.0.0",port=8765)
