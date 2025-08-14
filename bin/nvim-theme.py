#!/usr/bin/env python3
"""
nvim-theme.py - Python client for nvim-theme-ipc plugin
"""

import json
import socket
import sys
import os
import argparse
from pathlib import Path
from typing import Dict, List, Optional, Any

class NvimThemeClient:
    """Client for communicating with nvim-theme-ipc plugin"""
    
    def __init__(self):
        self.socket_path = self._get_socket_path()
    
    def _get_socket_path(self) -> str:
        """Get the socket path from cache file"""
        cache_dir = os.environ.get('XDG_CACHE_HOME', os.path.expanduser('~/.cache'))
        socket_file = Path(cache_dir) / 'nvim' / 'theme_socket'
        
        if not socket_file.exists():
            raise FileNotFoundError(
                f"Neovim theme server not running or socket file not found at {socket_file}"
            )
        
        socket_path = socket_file.read_text().strip()
        
        if not Path(socket_path).exists():
            raise FileNotFoundError(f"Socket {socket_path} does not exist")
        
        return socket_path
    
    def _send_command(self, command: Dict[str, Any]) -> Dict[str, Any]:
        """Send command to Neovim and return response"""
        try:
            sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
            sock.settimeout(5.0)  # 5 second timeout
            sock.connect(self.socket_path)
            
            message = json.dumps(command) + '\n'
            sock.send(message.encode())
            
            response = sock.recv(4096).decode().strip()
            sock.close()
            
            return json.loads(response)
        except socket.timeout:
            return {"error": "Connection timeout"}
        except ConnectionRefusedError:
            return {"error": "Connection refused - is Neovim running?"}
        except Exception as e:
            return {"error": str(e)}
    
    def set_theme(self, theme_name: str) -> bool:
        """Change to specified theme"""
        result = self._send_command({"action": "set_theme", "theme": theme_name})
        
        if result.get("success"):
            print(f"✓ Theme changed to: {result['theme']}")
            return True
        else:
            print(f"✗ Error: {result.get('error', 'Unknown error')}", file=sys.stderr)
            return False
    
    def get_theme(self) -> Optional[str]:
        """Get current theme name"""
        result = self._send_command({"action": "get_theme"})
        
        if "current_theme" in result:
            return result["current_theme"]
        else:
            print(f"✗ Error: {result.get('error', 'Unknown error')}", file=sys.stderr)
            return None
    
    def list_themes(self) -> List[str]:
        """List available themes"""
        result = self._send_command({"action": "list_themes"})
        
        if "themes" in result:
            return result["themes"]
        else:
            print(f"✗ Error: {result.get('error', 'Unknown error')}", file=sys.stderr)
            return []
    
    def reload_config(self) -> bool:
        """Reload Neovim configuration"""
        result = self._send_command({"action": "reload_config"})
        
        if result.get("success"):
            print("✓ Configuration reloaded")
            return True
        else:
            print(f"✗ Error: {result.get('error', 'Unknown error')}", file=sys.stderr)
            return False
    
    def status(self) -> bool:
        """Check server status"""
        try:
            current = self.get_theme()
            if current:
                print("✓ Neovim theme server is running")
                print(f"  Socket: {self.socket_path}")
                print(f"  Current theme: {current}")
                return True
        except Exception as e:
            print(f"✗ Error checking status: {e}", file=sys.stderr)
        
        print("✗ Neovim theme server is not responding")
        return False

def create_parser() -> argparse.ArgumentParser:
    """Create command line argument parser"""
    parser = argparse.ArgumentParser(
        prog='nvim-theme',
        description='Control Neovim themes from command line',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  nvim-theme set tokyonight    Change to tokyonight theme
  nvim-theme get               Show current theme
  nvim-theme list              List available themes
  nvim-theme status            Check server status
        """
    )
    
    subparsers = parser.add_subparsers(dest='command', help='Available commands')
    
    # Set theme command
    set_parser = subparsers.add_parser('set', help='Change to specified theme')
    set_parser.add_argument('theme', help='Theme name to switch to')
    
    # Get theme command
    subparsers.add_parser('get', help='Get current theme name')
    
    # List themes command
    subparsers.add_parser('list', help='List available themes')
    
    # Reload config command
    subparsers.add_parser('reload', help='Reload Neovim configuration')
    
    # Status command
    subparsers.add_parser('status', help='Check server status')
    
    return parser

def main():
    """Main entry point"""
    parser = create_parser()
    args = parser.parse_args()
    
    if not args.command:
        parser.print_help()
        sys.exit(1)
    
    try:
        client = NvimThemeClient()
    except FileNotFoundError as e:
        print(f"✗ {e}", file=sys.stderr)
        sys.exit(1)
    
    success = True
    
    if args.command == 'set':
        success = client.set_theme(args.theme)
    
    elif args.command == 'get':
        theme = client.get_theme()
        if theme:
            print(theme)
        else:
            success = False
    
    elif args.command == 'list':
        themes = client.list_themes()
        if themes:
            for theme in sorted(themes):
                print(theme)
        else:
            success = False
    
    elif args.command == 'reload':
        success = client.reload_config()
    
    elif args.command == 'status':
        success = client.status()
    
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()
