import os

files = [
    r'c:\Source code\traffic_detect\lib\screens\login_screen.dart',
    r'c:\Source code\traffic_detect\lib\screens\register_screen.dart',
    r'c:\Source code\traffic_detect\lib\screens\forgot_password_screen.dart'
]

replacements = {
    'AppColors.onSurface': 'Theme.of(context).colorScheme.onSurface',
    'AppColors.onSurfaceVariant': 'Theme.of(context).colorScheme.onSurfaceVariant',
    'AppColors.surfaceContainerHigh': 'Theme.of(context).colorScheme.surfaceVariant',
    'AppColors.surfaceContainer': 'Theme.of(context).colorScheme.surfaceVariant',
    'Colors.white.withOpacity(0.04)': 'Theme.of(context).colorScheme.onSurface.withOpacity(0.04)',
    'Colors.white54': 'Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5)',
    'Colors.white': 'Theme.of(context).colorScheme.onSurface'
}

for file_path in files:
    if not os.path.exists(file_path):
        continue
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    for old, new in replacements.items():
        content = content.replace(old, new)
        
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
