import os
import django
from django.core.asgi import get_asgi_application
import socketio

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'medical_robot.settings')
django.setup()

django_asgi_app = get_asgi_application()

# Initialize SocketIO in ASGI mode
sio = socketio.AsyncServer(
    async_mode='asgi', 
    cors_allowed_origins='*', 
    logger=True, 
    engineio_logger=True
)

# Register events
from robot.sockets import register_events
register_events(sio)

# Track if background tasks have started
_background_tasks_started = False

@sio.event
async def connect(sid, environ):
    """Handle client connection and start background tasks on first connection"""
    global _background_tasks_started
    if not _background_tasks_started:
        _background_tasks_started = True
        from robot.tasks import start_background_tasks
        start_background_tasks(sio)
        print("✅ Background tasks started on first connection")

# Create ASGI application
application = socketio.ASGIApp(sio, django_asgi_app)

