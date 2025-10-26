export const functionRegex = /(^z\..*)\(\)\s*\{/;

export const positionalArgRegex = /^\#\s*\$(\d+)(\?)?:\s*(.+)$/;

export const specialArgRegex = /^\#\s*\$(@)(\?)?:\s*(.+)$/;

export const namedArgRegex = /^\#\s*\$([a-z_][a-z0-9_]*)(\?)?:\s*(.+)$/i;
