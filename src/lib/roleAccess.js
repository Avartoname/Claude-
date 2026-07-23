// Role-based access control for navigation and routes
// null = full access; { denied } = everything except listed paths; { allowed } = only listed paths
const ROLE_ACCESS = {
  admin: null,
  manager: null,
  "team leader": {
    denied: ["/finance", "/stripe", "/franchise", "/executive", "/app-builder", "/kpi"],
  },
  "assistant team leader": {
    allowed: ["/", "/bookings", "/parties", "/party-charts", "/customers", "/staff", "/reviews", "/schools"],
  },
  assistant: {
    allowed: ["/bookings"],
  },
  user: {
    allowed: ["/bookings"],
  },
};

// Applied when a user has no role, or a role string that isn't recognized above.
// Fails closed rather than granting full access.
const DEFAULT_ACCESS = { allowed: ["/bookings"] };

function getAccess(role) {
  if (role && Object.prototype.hasOwnProperty.call(ROLE_ACCESS, role)) {
    return ROLE_ACCESS[role];
  }
  return DEFAULT_ACCESS;
}

export function canAccessPath(role, path) {
  const access = getAccess(role);
  if (!access) return true;
  if (access.denied) return !access.denied.includes(path);
  if (access.allowed) return access.allowed.includes(path);
  return true;
}

export function filterNavGroups(role, navGroups) {
  return navGroups
    .map((group) => ({
      ...group,
      items: group.items.filter((item) => item.external || canAccessPath(role, item.path)),
    }))
    .filter((group) => group.items.length > 0);
}
