#!/usr/bin/env python
"""
Run the Medical Robot Django server with uvicorn (ASGI mode).
This is required for WebSocket support!

Usage:
    python run_server.py [--host HOST] [--port PORT]

By default, binds to 0.0.0.0:8080 for network access.
"""
import os
import sys
import argparse

def main():
    parser = argparse.ArgumentParser(description='Run Medical Robot Server')
    parser.add_argument('--host', default='0.0.0.0', help='Host to bind to (default: 0.0.0.0)')
    parser.add_argument('--port', type=int, default=8080, help='Port to bind to (default: 8080)')
    parser.add_argument('--reload', action='store_true', help='Enable auto-reload for development')
    args = parser.parse_args()

    # Set Django settings module
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'medical_robot.settings')

    # Import uvicorn and run
    try:
        import uvicorn
    except ImportError:
        print("Error: uvicorn not installed. Run: pip install uvicorn")
        sys.exit(1)

    print(f"""
╔══════════════════════════════════════════════════════════════╗
║        Medical Delivery Robot - Django ASGI Server           ║
╠══════════════════════════════════════════════════════════════╣
║  Server: http://{args.host}:{args.port}                              
║  WebSocket: ws://{args.host}:{args.port}/socket.io/                  
╚══════════════════════════════════════════════════════════════╝
    """)

    # Run with uvicorn (ASGI server)
    uvicorn.run(
        "medical_robot.asgi:application",
        host=args.host,
        port=args.port,
        reload=args.reload,
        log_level="info",
        access_log=True,
    )

if __name__ == "__main__":
    main()
