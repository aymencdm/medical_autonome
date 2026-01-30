from django.apps import AppConfig
import threading
import sys

class RobotConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'robot'

    def ready(self):
        # Prevent initialization during migrations or management commands
        if 'runserver' not in sys.argv:
            return
            
        # Initialize Hardware here if needed, or lazy load it in Views/Sockets
        # For now, we'll let the singleton pattern in hardware modules handle it
        pass
