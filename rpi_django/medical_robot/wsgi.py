import os
import socketio
from django.core.wsgi import get_wsgi_application

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'medical_robot.settings')

# Initialize Django App
django_app = get_wsgi_application()

# Initialize SocketIO
sio = socketio.Server(async_mode='threading', cors_allowed_origins='*', logger=True, engineio_logger=True)

# Import event handlers (Must be done after sio init to avoid circular imports if structured poorly, 
# but usually done by importing the sockets module where @sio.event are defined)
from robot.sockets import register_events
register_events(sio)

# Wrap Django with SocketIO middleware
application = socketio.WSGIApp(sio, django_app)

# Start Background Tasks (Camera, Tracking)
from robot.tasks import start_background_tasks
start_background_tasks(sio)
