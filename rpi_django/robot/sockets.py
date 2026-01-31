from .hardware.config import CONFIG
from .hardware_manager import hardware

NS = CONFIG["NETWORK"]["NAMESPACE"]

def register_events(sio):
    
    @sio.on('connect', namespace=NS)
    async def on_connect(sid, environ):
        hardware.state["streaming"] = True
        
        # Ensure background tasks are running
        from .tasks import start_background_tasks
        start_background_tasks(sio)
        
        await sio.emit('status', {"pan": hardware.state["pan"], "tilt": hardware.state["tilt"], "tracking": hardware.state["auto_tracking"]}, room=sid, namespace=NS)

    @sio.on('disconnect', namespace=NS)
    async def on_disconnect(sid):
        pass

    @sio.on('toggle_tracking', namespace=NS)
    async def on_toggle(sid, data):
        hardware.state["auto_tracking"] = data.get("enabled", not hardware.state["auto_tracking"])

    @sio.on('manual_move', namespace=NS)
    async def on_manual(sid, data):
        hardware.state["auto_tracking"] = False
        if 'pan' in data: hardware.state["pan"] = data['pan']
        if 'tilt' in data: hardware.state["tilt"] = data['tilt']

    @sio.on('center', namespace=NS)
    async def on_center(sid):
        hardware.state["pan"] = CONFIG["SERVOS"]["CENTER_PAN"]
        hardware.state["tilt"] = CONFIG["SERVOS"]["CENTER_TILT"]

    @sio.on('start_stream', namespace=NS)
    async def on_start_stream(sid):
        hardware.state["streaming"] = True

    @sio.on('stop_stream', namespace=NS)
    async def on_stop_stream(sid):
        hardware.state["streaming"] = False

    @sio.on('capture_frame', namespace=NS)
    async def on_capture_frame(sid, data):
        if 'patient_id' in data:
            hardware.state["trigger_capture"] = {
                "patient_id": data['patient_id'],
                "timestamp": data.get('timestamp') 
            }
