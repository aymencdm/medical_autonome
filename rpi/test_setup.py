#!/usr/bin/env python3
"""
Test script to verify RTP streaming setup
Run this on your Raspberry Pi to check if everything is configured correctly
"""

import subprocess
import sys
import socket

def print_header(text):
    print("\n" + "=" * 60)
    print(f"  {text}")
    print("=" * 60)

def check_python_packages():
    print_header("Checking Python Packages")
    
    packages = ['flask', 'picamera2']
    all_ok = True
    
    for package in packages:
        try:
            __import__(package)
            print(f"✓ {package} is installed")
        except ImportError:
            print(f"✗ {package} is NOT installed")
            all_ok = False
    
    return all_ok

def check_gstreamer():
    print_header("Checking GStreamer")
    
    try:
        result = subprocess.run(
            ['gst-launch-1.0', '--version'],
            capture_output=True,
            text=True,
            timeout=5
        )
        
        if result.returncode == 0:
            version = result.stdout.split('\n')[0]
            print(f"✓ GStreamer is installed: {version}")
            return True
        else:
            print("✗ GStreamer is NOT installed")
            return False
    except FileNotFoundError:
        print("✗ GStreamer is NOT installed")
        return False
    except Exception as e:
        print(f"✗ Error checking GStreamer: {e}")
        return False

def check_network():
    print_header("Network Information")
    
    try:
        hostname = socket.gethostname()
        ip_address = socket.gethostbyname(hostname)
        print(f"✓ Hostname: {hostname}")
        print(f"✓ IP Address: {ip_address}")
        print(f"\n  Use this IP in your Flutter app: {ip_address}")
        return True
    except Exception as e:
        print(f"✗ Error getting network info: {e}")
        return False

def check_ports():
    print_header("Checking Port Availability")
    
    ports = {
        5000: "RTP Stream",
        5001: "RTCP Control",
        8080: "HTTP API"
    }
    
    all_ok = True
    
    for port, description in ports.items():
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(1)
        result = sock.connect_ex(('127.0.0.1', port))
        sock.close()
        
        if result != 0:
            print(f"✓ Port {port} ({description}) is available")
        else:
            print(f"⚠ Port {port} ({description}) is already in use")
            all_ok = False
    
    return all_ok

def main():
    print("\n" + "=" * 60)
    print("  RTP Streaming Setup Verification")
    print("=" * 60)
    
    results = {
        "Python Packages": check_python_packages(),
        "GStreamer": check_gstreamer(),
        "Network": check_network(),
        "Ports": check_ports()
    }
    
    print_header("Summary")
    
    all_passed = True
    for test, passed in results.items():
        status = "✓ PASS" if passed else "✗ FAIL"
        print(f"{status}: {test}")
        if not passed:
            all_passed = False
    
    print("\n" + "=" * 60)
    
    if all_passed:
        print("✓ All checks passed! You're ready to run the RTP server.")
        print("\nNext steps:")
        print("  1. Run: python app_rtp.py")
        print("  2. Open Flutter app on your phone")
        print("  3. Enter the IP address shown above")
        print("  4. Start streaming!")
    else:
        print("✗ Some checks failed. Please fix the issues above.")
        print("\nTo install missing components:")
        print("  Python packages: pip install -r requirements_rtp.txt")
        print("  GStreamer: sudo apt-get install gstreamer1.0-tools ...")
    
    print("=" * 60 + "\n")
    
    return 0 if all_passed else 1

if __name__ == '__main__':
    sys.exit(main())
