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

export function canAccessPath(role, path) {
  if (!role) return true;
  const access = ROLE_ACCESS[role];
  if (!access) return true;
  if (access.denied) return !access.denied.includes(path);
  if (access.allowed) return access.allowed.includes(path);
  return true;
}

export function filterNavGroups(role, navGroups) {
  if (!role) return navGroups;
  return navGroups
    .map((group) => ({
      ...group,
      items: group.items.filter((item) => item.external || canAccessPath(role, item.path)),
    }))
    .filter((group) => group.items.length > 0);
}
