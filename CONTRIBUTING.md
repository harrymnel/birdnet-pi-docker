# Contributing to BirdNET-Pi Docker

Thank you for your interest in contributing to this project! This document provides guidelines for contributing to the BirdNET-Pi Docker implementation with RTSP support.

## 🤝 How to Contribute

### Reporting Issues

Before creating an issue, please:

1. **Check existing issues** to avoid duplicates
2. **Use the search function** to find similar problems
3. **Include system information**:
   - Windows version (Windows 10/11)
   - Docker Desktop version
   - Raspberry Pi model and OS version
   - Hardware specifications (camera, microphone)

#### Issue Template

```markdown
**Bug Description**
A clear description of the bug.

**System Information**
- OS: Windows 11 Pro
- Docker Desktop: v4.x.x
- Raspberry Pi: Model 4B, Raspberry Pi OS Bullseye
- Camera: [USB camera model]
- Microphone: [USB microphone model]

**Steps to Reproduce**
1. Step one
2. Step two
3. Step three

**Expected Behavior**
What should happen

**Actual Behavior**
What actually happens

**Logs**
```
Paste relevant logs here
```

**Additional Context**
Any other relevant information
```

### Feature Requests

We welcome feature requests! Please include:

- **Use case**: Why would this feature be useful?
- **Implementation ideas**: How might this work?
- **Alternatives considered**: What other solutions did you consider?

## 💻 Development Setup

### Prerequisites

- Windows 11 with Docker Desktop
- Git for Windows
- VS Code (recommended)
- Raspberry Pi with camera/microphone setup

### Local Development

1. **Fork and clone the repository**:
   ```bash
   git clone https://github.com/yourusername/birdnet-pi-docker.git
   cd birdnet-pi-docker
   ```

2. **Create a development branch**:
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Set up development environment**:
   ```bash
   # Copy example configuration
   cp config/birdnet.conf.example config/birdnet.conf
   
   # Edit with your RTSP stream details
   # Build and test
   docker-compose build
   docker-compose up -d
   ```

### Testing Changes

Before submitting changes:

1. **Test basic functionality**:
   ```bash
   # Verify container starts
   docker-compose ps
   
   # Check web interface
   curl -I http://localhost:8001
   
   # Verify RTSP connection
   docker-compose logs | grep "READ.*CHUNKS"
   ```

2. **Test audio processing** (if applicable):
   ```bash
   # Check recent recordings
   docker-compose exec birdnet-pi ls -la /config/BirdSongs/By_Date/$(date +%Y-%m-%d)/
   
   # Verify file sizes (should be >1KB)
   docker-compose exec birdnet-pi find /config/BirdSongs -name "*.mp3" -exec ls -lh {} \;
   ```

3. **Test sleep/wake recovery**:
   - Put Windows system to sleep
   - Wake system
   - Verify container recovers automatically
   - Check for any FileNotFoundError messages

## 📝 Code Guidelines

### Dockerfile Best Practices

- **Use specific base image versions** when possible
- **Combine RUN commands** to reduce layers
- **Add verification steps** for modifications
- **Include clear comments** for complex operations

Example:
```dockerfile
# Apply RTSP TCP transport fix with verification
RUN sed -i 's/pattern/replacement/g' /path/to/script && \
    grep "expected_result" /path/to/script || \
    (echo "ERROR: Fix not applied!" && exit 1)
```

### Docker Compose Guidelines

- **Use environment variables** for configuration
- **Include health checks** where appropriate
- **Set appropriate restart policies**
- **Document port mappings**

### Documentation Standards

- **Use clear headings** and structure
- **Include code examples** for complex procedures
- **Test all commands** before including them
- **Add troubleshooting sections** for common issues

## 🧪 Testing

### Test Categories

1. **Basic Functionality Tests**
   - Container startup
   - Web interface accessibility
   - RTSP stream connection
   - Audio file generation

2. **Audio Processing Tests**
   - PulseAudio setup on Pi
   - Audio quality improvements
   - Species detection accuracy

3. **Resilience Tests**
   - Sleep/wake recovery
   - Network disconnection recovery
   - Container restart scenarios

4. **Performance Tests**
   - Resource usage monitoring
   - Long-term stability
   - Detection rate analysis

### Test Environment Setup

Create a test configuration in `config/test_birdnet.conf`:
```bash
# Test configuration with lower thresholds
CONFIDENCE=0.5
SENSITIVITY=1.0
RECORDING_LENGTH=5
```

## 🚀 Submitting Changes

### Pull Request Process

1. **Create focused PRs**: One feature or fix per PR
2. **Update documentation**: Include relevant doc updates
3. **Test thoroughly**: Verify changes work as expected
4. **Follow commit conventions**: Use clear, descriptive commit messages

#### Commit Message Format

```
type(scope): brief description

Longer explanation of the change, if needed.

- List specific changes
- Reference issues: Fixes #123
```

Types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`

Example:
```
feat(audio): add PulseAudio echo cancellation support

Implements WebRTC-based echo cancellation for improved bird detection.
Includes automatic setup script and configuration validation.

- Add PulseAudio system service configuration
- Create audio processing pipeline with noise reduction
- Update documentation with setup instructions

Fixes #45
```

### PR Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Performance improvement
- [ ] Refactoring

## Testing
- [ ] Tested on Windows 11 Docker Desktop
- [ ] Verified RTSP stream connectivity  
- [ ] Confirmed audio processing works
- [ ] Checked sleep/wake recovery
- [ ] Updated relevant documentation

## Checklist
- [ ] Code follows project style guidelines
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] No breaking changes (or clearly documented)
```

## 📖 Documentation Contributions

### Areas Needing Documentation

- **Hardware setup guides** for different Pi/camera combinations
- **Troubleshooting guides** for specific issues
- **Performance optimization** tips
- **Integration examples** with other systems

### Documentation Style

- Use **clear, actionable language**
- Include **copy-paste commands** where possible
- Add **screenshots** for UI-related instructions
- Provide **troubleshooting steps** for each procedure

## 🏆 Recognition

Contributors are recognized in several ways:

- **README acknowledgments** for significant contributions
- **GitHub contributor graph** shows all code contributions
- **Release notes** credit feature and fix contributors
- **Documentation credits** for major documentation improvements

## 🤔 Questions?

- **General questions**: Open a [Discussion](https://github.com/yourusername/birdnet-pi-docker/discussions)
- **Bug reports**: Create an [Issue](https://github.com/yourusername/birdnet-pi-docker/issues)
- **Feature requests**: Use [Feature Request template](https://github.com/yourusername/birdnet-pi-docker/issues/new?template=feature_request.md)

## 📋 Priority Areas

Current priority areas for contributions:

1. **Audio Processing Improvements**
   - Additional noise reduction algorithms
   - Automatic gain control optimization
   - Real-time audio quality monitoring

2. **Hardware Compatibility**
   - Support for additional camera models
   - USB microphone optimization guides
   - Audio isolator integration testing

3. **Performance Optimization**
   - Container resource usage reduction
   - Detection algorithm tuning
   - Storage optimization

4. **Documentation**
   - Video setup tutorials
   - Hardware recommendation guides
   - Advanced configuration examples

Thank you for contributing to BirdNET-Pi Docker! 🐦