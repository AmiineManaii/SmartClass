import type { ChatTool } from '../domain/ai-gateway.port.js';

/**
 * Tools advertised to the local model (Unsloth Desktop tool calling,
 * OpenAI-compatible `tools` parameter + Unsloth execution flags
 * `enable_tools`, `tool_servers`, `auto_execute_tools`,
 * `max_tool_iterations`). The server executes the tools when supported;
 * otherwise the gateway retries without tools.
 */
export const WEB_SEARCH_TOOL: ChatTool = {
  type: 'function',
  function: {
    name: 'web_search',
    description:
      'Recherche des informations récentes sur le web via un moteur de recherche.',
    parameters: {
      type: 'object',
      properties: {
        query: { type: 'string', description: 'La requête de recherche' },
        max_results: { type: 'integer', default: 10 },
      },
      required: ['query'],
      additionalProperties: false,
    },
  },
};

export const FETCH_URL_TOOL: ChatTool = {
  type: 'function',
  function: {
    name: 'fetch_url',
    description: "Récupère et extrait le contenu textuel d'une page web.",
    parameters: {
      type: 'object',
      properties: {
        url: { type: 'string', description: "L'URL à récupérer" },
      },
      required: ['url'],
      additionalProperties: false,
    },
  },
};

export const EXECUTE_CODE_TOOL: ChatTool = {
  type: 'function',
  function: {
    name: 'execute_code',
    description: 'Exécute du code Python dans un environnement sandboxé.',
    parameters: {
      type: 'object',
      properties: {
        language: {
          type: 'string',
          enum: ['python', 'javascript', 'bash'],
          description: 'Le langage du code à exécuter',
        },
        code: { type: 'string', description: 'Le code à exécuter' },
      },
      required: ['language', 'code'],
      additionalProperties: false,
    },
  },
};

export const CALCULATOR_TOOL: ChatTool = {
  type: 'function',
  function: {
    name: 'calculator',
    description: 'Évalue une expression mathématique.',
    parameters: {
      type: 'object',
      properties: {
        expression: { type: 'string', description: "L'expression à évaluer" },
      },
      required: ['expression'],
      additionalProperties: false,
    },
  },
};

/** Full Unsloth toolset offered for course generation. */
export const COURSE_TOOLS: ChatTool[] = [
  WEB_SEARCH_TOOL,
  FETCH_URL_TOOL,
  EXECUTE_CODE_TOOL,
  CALCULATOR_TOOL,
];

export const COURSE_TOOL_NAMES = ['web_search', 'fetch_url', 'execute_code', 'calculator'];
