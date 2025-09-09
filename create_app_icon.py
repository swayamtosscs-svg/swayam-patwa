#!/usr/bin/env python3
"""
Script to create app icons from logo-rgram.png
This script will create the necessary icon sizes for Android and iOS
"""

import os
from PIL import Image
import shutil

def create_app_icons():
    # Source logo file
    source_logo = "assets/images/app-icon.jpeg"
    
    if not os.path.exists(source_logo):
        print(f"Error: {source_logo} not found!")
        return
    
    # Android mipmap directories and sizes
    android_icons = {
        "mipmap-mdpi": 48,
        "mipmap-hdpi": 72,
        "mipmap-xhdpi": 96,
        "mipmap-xxhdpi": 144,
        "mipmap-xxxhdpi": 192
    }
    
    # Create Android icons
    for directory, size in android_icons.items():
        android_path = f"android/app/src/main/res/{directory}"
        os.makedirs(android_path, exist_ok=True)
        
        # Create ic_launcher.png
        icon_path = f"{android_path}/ic_launcher.png"
        create_icon(source_logo, icon_path, size, size)
        print(f"Created {icon_path} ({size}x{size})")
        
        # Create ic_launcher_round.png (optional)
        round_icon_path = f"{android_path}/ic_launcher_round.png"
        create_round_icon(source_logo, round_icon_path, size, size)
        print(f"Created {round_icon_path} ({size}x{size})")
    
    # Create adaptive icon files
    create_adaptive_icons()
    
    print("\nApp icons created successfully!")
    print("You may need to clean and rebuild your app for changes to take effect.")

def create_icon(source_path, output_path, width, height):
    """Create a simple icon by resizing the source image"""
    try:
        with Image.open(source_path) as img:
            # Convert to RGBA if necessary
            if img.mode != 'RGBA':
                img = img.convert('RGBA')
            
            # Resize image
            resized_img = img.resize((width, height), Image.Resampling.LANCZOS)
            
            # Save icon
            resized_img.save(output_path, 'PNG')
    except Exception as e:
        print(f"Error creating icon {output_path}: {e}")

def create_round_icon(source_path, output_path, width, height):
    """Create a round icon by adding circular mask"""
    try:
        with Image.open(source_path) as img:
            # Convert to RGBA if necessary
            if img.mode != 'RGBA':
                img = img.convert('RGBA')
            
            # Resize image
            resized_img = img.resize((width, height), Image.Resampling.LANCZOS)
            
            # Create circular mask
            mask = Image.new('L', (width, height), 0)
            
            # Create circular mask
            for y in range(height):
                for x in range(width):
                    # Calculate distance from center
                    center_x, center_y = width // 2, height // 2
                    distance = ((x - center_x) ** 2 + (y - center_y) ** 2) ** 0.5
                    radius = min(width, height) // 2
                    
                    if distance <= radius:
                        mask.putpixel((x, y), 255)
            
            # Apply mask
            output_img = Image.new('RGBA', (width, height), (0, 0, 0, 0))
            output_img.paste(resized_img, (0, 0))
            output_img.putalpha(mask)
            
            # Save round icon
            output_img.save(output_path, 'PNG')
    except Exception as e:
        print(f"Error creating round icon {output_path}: {e}")

def create_adaptive_icons():
    """Create adaptive icon files for modern Android"""
    try:
        # Create foreground and background icons for adaptive icons
        source_logo = "assets/images/app-icon.jpeg"
        
        # Create foreground icon (108dp = 108px for mdpi)
        foreground_path = "android/app/src/main/res/mipmap-mdpi/ic_launcher_foreground.png"
        create_icon(source_logo, foreground_path, 108, 108)
        
        # Create background icon (108dp = 108px for mdpi)
        background_path = "android/app/src/main/res/mipmap-mdpi/ic_launcher_background.png"
        create_solid_background(background_path, 108, 108, (99, 102, 241))  # #6366F1 color
        
        print("Created adaptive icon files")
    except Exception as e:
        print(f"Error creating adaptive icons: {e}")

def create_solid_background(output_path, width, height, color):
    """Create a solid color background image"""
    try:
        img = Image.new('RGBA', (width, height), color)
        img.save(output_path, 'PNG')
    except Exception as e:
        print(f"Error creating background: {e}")

if __name__ == "__main__":
    create_app_icons()
