import sys, re, glob

for file in glob.glob('ASSETS/DIALOGIC/TIMELINES/*.dtl'):
    with open(file, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    new_lines = []
    i = 0
    while i < len(lines):
        line = lines[i]
        
        # Check if current line is a blocking command
        if ('join ' in line or 'leave ' in line) and 'wait="true"' in line:
            # Look ahead for audio commands
            j = i + 1
            moved_audios = []
            while j < len(lines):
                next_line = lines[j]
                if next_line.strip().startswith('audio '):
                    moved_audios.append(next_line)
                    lines[j] = '' # Mark for removal
                    j += 1
                elif next_line.strip().startswith('[wait '):
                    # Skip wait commands, keep looking for audio
                    j += 1
                else:
                    break
            
            if moved_audios:
                new_lines.extend(moved_audios)
                
        if line != '':
            new_lines.append(line)
        i += 1
        
    with open(file, 'w', encoding='utf-8') as f:
        f.writelines(new_lines)

print('Reordered audio successfully.')
