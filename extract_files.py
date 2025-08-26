#!/usr/bin/env python3
import re
import os

def extract_swift_files(input_file):
    with open(input_file, 'r') as f:
        content = f.read()
    
    # Pattern to match file paths and their code blocks
    pattern = r'### \*\*(.+?\.swift)\*\*\n```swift\n(.*?)\n```'
    
    matches = re.findall(pattern, content, re.DOTALL)
    
    for filepath, code in matches:
        # Clean up the file path
        filepath = filepath.strip()
        
        # Create full path
        full_path = os.path.join('/Users/fredrickburns/Code_Repositories/StudentAnalysisSystem', filepath)
        
        # Create directory if it doesn't exist
        os.makedirs(os.path.dirname(full_path), exist_ok=True)
        
        # Write the file
        with open(full_path, 'w') as f:
            f.write(code)
        
        print(f"Written: {filepath}")

if __name__ == "__main__":
    extract_swift_files('remaining_files.txt')
    print("\nExtraction complete!")