# Security Policy

## Supported Versions

We provide security updates for the following versions:

| Version | Supported          |
| ------- | ------------------ |
| Latest  | ✅ Yes             |
| Previous| ❌ No              |

## Reporting a Vulnerability

If you discover a security vulnerability in this project, please report it responsibly:

### 🔒 Private Disclosure Process

1. **DO NOT** create a public GitHub issue for security vulnerabilities
2. **Email** security concerns to: [harrymnel@gmail.com]
3. **Include** the following information:
   - Description of the vulnerability
   - Steps to reproduce the issue
   - Potential impact assessment
   - Suggested fix (if known)

### 📋 What to Include

- **Detailed description** of the vulnerability
- **Reproduction steps** with specific configuration details
- **System information** (OS, Docker version, etc.)
- **Potential impact** on users and systems
- **Your contact information** for follow-up questions

### ⏱️ Response Timeline

- **Initial response**: Within 48 hours
- **Detailed assessment**: Within 1 week
- **Fix development**: Depends on severity and complexity
- **Public disclosure**: After fix is released

### 🛡️ Security Considerations for Users

#### Docker Container Security
- Keep Docker Desktop updated to the latest version
- Regularly update the BirdNET-Pi container image
- Use non-root user when possible
- Limit container network exposure

#### Network Security
- **RTSP streams** are unencrypted by default
- Consider using VPN for remote access
- Implement firewall rules for exposed ports
- Use strong authentication for web interfaces

#### Audio Recording Privacy
- **Be aware** of local laws regarding audio recording
- **Consider privacy implications** of continuous recording
- **Secure storage** of recorded audio files
- **Regular cleanup** of old recordings

#### Configuration Security
- **Protect configuration files** containing sensitive information
- **Use environment variables** for secrets when possible
- **Regular backup** of configuration with proper access controls

### 🔄 Security Updates

Security updates are distributed through:
- **Docker Hub** with updated container images
- **GitHub Releases** with detailed security notes
- **Documentation updates** with security best practices

### 📝 Vulnerability Disclosure Policy

We follow responsible disclosure:
- **Private notification** to maintainers first
- **Collaborative fix development** with reporter
- **Public disclosure** only after fix is available
- **Credit to reporter** in release notes (if desired)

### 🤝 Security Community

We welcome security researchers and encourage:
- **Responsible disclosure** of vulnerabilities
- **Constructive feedback** on security practices
- **Contributions** to improve project security
- **Sharing** of security best practices

### 📚 Security Resources

- [Docker Security Best Practices](https://docs.docker.com/engine/security/)
- [Windows Security Guidelines](https://docs.microsoft.com/en-us/windows/security/)
- [Raspberry Pi Security](https://www.raspberrypi.org/documentation/configuration/security.md)

## Acknowledgments

We thank security researchers who help keep this project secure through responsible disclosure.

---

**Remember**: Security is a shared responsibility. Please help us keep the community safe by reporting vulnerabilities responsibly.