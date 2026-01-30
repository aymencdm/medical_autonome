from .hardware.config import CONFIG
from .hardware_manager import hardware

NS = CONFIG["NETWORK"]["NAMESPACE"]

def register_events(sio):
    
    @sio.on('connect', namespace=NS)
    def on_connect(sid, environ):
        hardware.state["streaming"] = True
        sio.emit('status', {"pan": hardware.state["pan"], "tilt": hardware.state["tilt"], "tracking": hardware.state["auto_tracking"]}, room=sid, namespace=NS)

    @sio.on('disconnect', namespace=NS)
    def on_disconnect(sid):
        pass

    @sio.on('toggle_tracking', namespace=NS)
    def on_toggle(sid, data):
        hardware.state["auto_tracking"] = data.get("enabled", not hardware.state["auto_tracking"])

    @sio.on('manual_move', namespace=NS)
    def on_manual(sid, data):
        hardware.state["auto_tracking"] = False
        if 'pan' in data: hardware.state["pan"] = data['pan']
        if 'tilt' in data: hardware.state["tilt"] = data['tilt']

    @sio.on('center', namespace=NS)
    def on_center(sid):
        hardware.state["pan"] = CONFIG["SERVOS"]["CENTER_PAN"]
        hardware.state["tilt"] = CONFIG["SERVOS"]["CENTER_TILT"]
