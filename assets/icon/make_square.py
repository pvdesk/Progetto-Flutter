import sys
from PIL import Image

def make_square(image_path, output_path, fill_color=(255, 255, 255, 255)):
    img = Image.open(image_path)
    # Convert to RGBA to ensure we can handle transparency if needed
    img = img.convert("RGBA")
    
    # Calculate the side length of the square
    max_dim = max(img.size)
    
    # Create a new image with the background color
    square_img = Image.new('RGBA', (max_dim, max_dim), fill_color)
    
    # Calculate offset to center the original image
    offset_x = (max_dim - img.size[0]) // 2
    offset_y = (max_dim - img.size[1]) // 2
    
    # Paste the original image using its own alpha channel as a mask
    square_img.paste(img, (offset_x, offset_y), img)
    
    # Save the result
    square_img.save(output_path, "PNG")
    print(f"Saved square image to {output_path}")

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python make_square.py <input> <output>")
        sys.exit(1)
    make_square(sys.argv[1], sys.argv[2])
