#!/usr/bin/env python3
import sys
import re
import os
import subprocess

def bump_version(new_marketing_version=None):
    project_yml_path = "project.yml"
    if not os.path.exists(project_yml_path):
        print(f"Error: {project_yml_path} not found.")
        return

    with open(project_yml_path, "r") as f:
        content = f.read()

    # Find the current project version (build number)
    build_matches = re.findall(r'CURRENT_PROJECT_VERSION:\s*"(\d+)"', content)
    if not build_matches:
        print("Could not find CURRENT_PROJECT_VERSION in project.yml")
        return
    
    current_build = int(build_matches[0])
    new_build = current_build + 1

    # Replace CURRENT_PROJECT_VERSION
    content = re.sub(r'CURRENT_PROJECT_VERSION:\s*"\d+"', f'CURRENT_PROJECT_VERSION: "{new_build}"', content)

    # Replace MARKETING_VERSION if provided
    if new_marketing_version:
        content = re.sub(r'MARKETING_VERSION:\s*"[\d\.]+"', f'MARKETING_VERSION: "{new_marketing_version}"', content)
        print(f"Bumping version to Marketing: {new_marketing_version}, Build: {new_build}")
    else:
        print(f"Bumping Build number to: {new_build}")

    with open(project_yml_path, "w") as f:
        f.write(content)

    print("Regenerating Xcode project...")
    try:
        subprocess.run(["xcodegen"], check=True)
        print("Successfully updated and regenerated Xcode project!")
    except subprocess.CalledProcessError as e:
        print(f"Error running xcodegen: {e}")

if __name__ == "__main__":
    marketing = sys.argv[1] if len(sys.argv) > 1 else None
    bump_version(marketing)
