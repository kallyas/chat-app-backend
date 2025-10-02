/**
 * Validates and sanitizes pagination parameters
 * @param page - Page number from query params (can be string or number)
 * @param limit - Items per page from query params (can be string or number)
 * @param maxLimit - Maximum allowed limit (default 100)
 * @returns Validated pagination parameters
 */
export function validatePagination(
  page: any,
  limit: any,
  maxLimit: number = 100
): { page: number; limit: number } {
  // Parse and validate page
  const parsedPage = parseInt(String(page), 10);
  const validPage = isNaN(parsedPage) || parsedPage < 1 ? 1 : parsedPage;

  // Parse and validate limit
  const parsedLimit = parseInt(String(limit), 10);
  let validLimit = isNaN(parsedLimit) || parsedLimit < 1 ? 20 : parsedLimit;

  // Cap limit at maxLimit
  validLimit = Math.min(validLimit, maxLimit);

  return {
    page: validPage,
    limit: validLimit
  };
}

/**
 * Calculate skip value for MongoDB queries
 * @param page - Page number (1-indexed)
 * @param limit - Items per page
 * @returns Number of items to skip
 */
export function calculateSkip(page: number, limit: number): number {
  return (page - 1) * limit;
}
