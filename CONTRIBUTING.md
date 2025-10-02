# Contributing to Chat App

Thank you for your interest in contributing to the Real-Time Chat Application! This document provides guidelines and instructions for contributing.

## Code of Conduct

By participating in this project, you agree to maintain a respectful and inclusive environment for all contributors.

## Getting Started

1. **Fork the repository** on GitHub
2. **Clone your fork** locally:
   ```bash
   git clone https://github.com/your-username/chat-app.git
   cd chat-app
   ```
3. **Add upstream remote**:
   ```bash
   git remote add upstream https://github.com/kallyas/chat-app.git
   ```

## Development Setup

1. **Install dependencies**:
   ```bash
   cd backend
   yarn install
   ```

2. **Set up environment variables**:
   ```bash
   cp .env.example .env
   # Edit .env with your local configuration
   ```

3. **Start development server**:
   ```bash
   yarn dev
   ```

## Development Workflow

### Creating a Feature Branch

```bash
# Update your local main branch
git checkout main
git pull upstream main

# Create a new feature branch
git checkout -b feature/your-feature-name
```

### Making Changes

1. **Write code** following the project's coding standards
2. **Write tests** for new features or bug fixes
3. **Run tests** to ensure everything works:
   ```bash
   yarn test
   ```
4. **Run linter** and fix any issues:
   ```bash
   yarn lint
   yarn lint:fix
   ```
5. **Format code**:
   ```bash
   yarn format
   ```
6. **Build** to ensure TypeScript compiles:
   ```bash
   yarn build
   ```

### Committing Changes

We follow conventional commit messages:

```bash
# Format: <type>(<scope>): <subject>

# Examples:
git commit -m "feat(auth): add password reset functionality"
git commit -m "fix(socket): prevent race condition in disconnect handler"
git commit -m "docs(readme): update installation instructions"
git commit -m "test(chat): add tests for message editing"
git commit -m "refactor(utils): simplify pagination logic"
```

**Commit Types**:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `test`: Adding or updating tests
- `refactor`: Code refactoring
- `perf`: Performance improvements
- `chore`: Maintenance tasks
- `style`: Code style changes (formatting)

### Pushing Changes

```bash
# Push to your fork
git push origin feature/your-feature-name
```

## Pull Request Process

1. **Create a Pull Request** from your fork to the main repository
2. **Fill out the PR template** with:
   - Description of changes
   - Related issue numbers (if applicable)
   - Testing done
   - Screenshots (if UI changes)

3. **Ensure all checks pass**:
   - ✅ Tests pass on all Node versions (18, 20, 22)
   - ✅ Linter passes
   - ✅ Build succeeds
   - ✅ Code coverage doesn't decrease

4. **Address review feedback** promptly

5. **Keep your PR up to date**:
   ```bash
   git checkout main
   git pull upstream main
   git checkout feature/your-feature-name
   git rebase main
   git push --force-with-lease origin feature/your-feature-name
   ```

## Coding Standards

### TypeScript

- Use **TypeScript** for all new code
- Define **interfaces** for all data structures
- Use **strict type checking** (no `any` unless absolutely necessary)
- Use **async/await** instead of callbacks

### Code Style

- **ESLint** configuration is enforced
- **Prettier** for code formatting
- **2 spaces** for indentation
- Use **meaningful variable names**
- Add **JSDoc comments** for public functions

### File Organization

```
backend/src/
├── config/         # Configuration files
├── controllers/    # HTTP request handlers
├── middleware/     # Express middleware
├── models/         # Mongoose models
├── routes/         # API routes
├── services/       # Business logic
├── sockets/        # Socket.IO handlers
├── types/          # TypeScript types/interfaces
└── utils/          # Helper functions
```

### Testing

- Write **unit tests** for utilities and services
- Write **integration tests** for API endpoints
- Aim for **>80% code coverage**
- Test files should be named `*.test.ts`
- Place tests in `src/tests/` directory

```typescript
// Example test structure
describe('AuthService', () => {
  describe('registerUser', () => {
    it('should create a new user', async () => {
      // Test implementation
    });

    it('should throw error for duplicate email', async () => {
      // Test implementation
    });
  });
});
```

### Error Handling

- Use **custom error classes** (`AppError`)
- Include **meaningful error messages**
- Log errors with **appropriate levels**
- Don't expose sensitive information in error messages

```typescript
// Good
throw new AppError('User not found', 404);

// Bad
throw new Error('Error occurred');
```

### Security

- **Never commit** sensitive data (API keys, passwords)
- Use **environment variables** for configuration
- **Validate** all user input
- **Sanitize** data before database operations
- Follow **OWASP** security guidelines

## Documentation

### Code Documentation

- Add **JSDoc comments** for functions
- Document **complex algorithms**
- Update **API documentation** when endpoints change
- Include **examples** in documentation

### README Updates

- Update the main README for new features
- Add configuration examples
- Update API endpoint documentation
- Include migration guides for breaking changes

## Issue Reporting

### Bug Reports

Include:
- **Description** of the bug
- **Steps to reproduce**
- **Expected behavior**
- **Actual behavior**
- **Environment** (Node version, OS, etc.)
- **Error messages** or logs
- **Screenshots** (if applicable)

### Feature Requests

Include:
- **Use case** description
- **Proposed solution**
- **Alternative solutions** considered
- **Additional context**

## Review Process

### For Contributors

- Be **responsive** to feedback
- Be **open** to suggestions
- **Explain** your decisions if challenged
- **Learn** from the review process

### For Reviewers

- Be **respectful** and constructive
- Focus on **code quality** and **project standards**
- **Explain** your suggestions
- **Approve** when satisfied with changes

## Release Process

Releases are managed by maintainers:

1. Version bump following **Semantic Versioning**
2. Update **CHANGELOG.md**
3. Create **GitHub release**
4. Deploy to production (if applicable)

## Questions?

- Open a **GitHub Issue** for questions
- Join our **Discord/Slack** (if available)
- Email maintainers (if urgent)

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

Thank you for contributing! 🎉
