class CustomAuthError(Exception):
    """Base exception for auth2 errors."""
    status_code = 400

    def __init__(self, message=None, status_code=None):
        self.message = message or self.__class__.__name__
        if status_code:
            self.status_code = status_code
        super().__init__(self.message)

class ExpiredTokenError(CustomAuthError):
    status_code = 440

class InvalidTokenError(CustomAuthError):
    status_code = 441

class TokenDecodingError(CustomAuthError):
    status_code = 442

class MissingUsernameError(CustomAuthError):
    status_code = 450

class InactiveUserError(CustomAuthError):
    status_code = 451

class ImpersonateTokenOnlyIsNotSufficientError(CustomAuthError):
    status_code = 452
