Debian Packaging Instructions
(Persian version: DEBIAN_PACKAGING.fa.md)

Your Team:

- Put your tool code in src/
- Put optional config files in config/
- Update debian/control with your team name and description.
- Update debian/changelog with team member information.
- Update debian/install if you rename files or add new ones.
- Update debian/links if you rename files or add new ones.
- Run `debuild -us -uc` to build the .deb package.

IMPORTANT: Rename all instances of "mytool" to your project name!

Files in debian/ directory:

- control: Package metadata (name, maintainer, dependencies, description)
- changelog: Version history
- install: Maps your files to system locations
- links: Maps installed files to other paths
- manpages: Registers your man page
- rules: Build instructions (usually no changes needed)
