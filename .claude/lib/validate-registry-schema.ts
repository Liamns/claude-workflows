#!/usr/bin/env node
/**
 * validate-registry-schema.ts
 * Validates command-resource-mapping.json using Zod schemas
 *
 * Usage: node validate-registry-schema.ts <registry-file.json>
 */

import { z } from 'zod';
import * as fs from 'fs';
import * as path from 'path';

// ============================================================================
// Zod Schemas (from data-model.md)
// ============================================================================

const CommandSchema = z.object({
  id: z.string().min(1).regex(/^[a-z0-9_-]+$/, 'Command ID must contain only lowercase letters, numbers, underscores, and hyphens'),
  name: z.string().min(1),
  description: z.string().min(10),
  filePath: z.string().regex(/^\.claude\/commands\/[a-z0-9_-]+\.md$/, 'Invalid command file path format'),
  relatedSkills: z.array(z.string()).optional().default([]),
  relatedAgents: z.array(z.string()).optional().default([]),
  relatedScripts: z.array(z.string()).optional().default([]),
  createdAt: z.string().datetime(),
  updatedAt: z.string().datetime(),
});

const SkillSchema = z.object({
  id: z.string().min(1).regex(/^[a-z0-9_-]+$/, 'Skill ID must contain only lowercase letters, numbers, underscores, and hyphens'),
  name: z.string().min(1),
  description: z.string().min(10),
  directoryPath: z.string().regex(/^\.claude\/skills\/[a-z0-9_-]+\/$/, 'Invalid skill directory path format'),
  usedByCommands: z.array(z.string()).optional().default([]),
  createdAt: z.string().datetime(),
  updatedAt: z.string().datetime(),
});

const AgentSchema = z.object({
  id: z.string().min(1).regex(/^[a-z0-9_-]+$/, 'Agent ID must contain only lowercase letters, numbers, underscores, and hyphens'),
  name: z.string().min(1),
  type: z.string().min(1),
  description: z.string().min(10),
  directoryPath: z.string().regex(/^\.claude\/agents\/[a-z0-9_-]+\/$/, 'Invalid agent directory path format'),
  usedByCommands: z.array(z.string()).optional().default([]),
  createdAt: z.string().datetime(),
  updatedAt: z.string().datetime(),
});

const ScriptSchema = z.object({
  id: z.string().min(1),
  name: z.string().min(1),
  filePath: z.string().regex(/\.sh$/, 'Script file must end with .sh'),
  category: z.enum(['lib', 'hooks', 'agent-specific', 'test']),
  description: z.string().min(10),
  usedByCommands: z.array(z.string()).optional().default([]),
  usedBySkills: z.array(z.string()).optional().default([]),
  usedByAgents: z.array(z.string()).optional().default([]),
  createdAt: z.string().datetime(),
  updatedAt: z.string().datetime(),
});

const DocumentSectionSchema = z.object({
  name: z.string().min(1),
  required: z.boolean(),
  present: z.boolean(),
  content: z.string().optional(),
});

const DocumentationSchema = z.object({
  id: z.string().min(1),
  commandId: z.string().min(1),
  filePath: z.string().regex(/^\.claude\/commands\/[a-z0-9_-]+\.md$/, 'Invalid documentation file path format'),
  sections: z.array(DocumentSectionSchema),
  templateCompliance: z.boolean(),
  createdAt: z.string().datetime(),
  updatedAt: z.string().datetime(),
});

const CommandResourceRegistrySchema = z.object({
  version: z.string().regex(/^\d+\.\d+\.\d+$/, 'Version must be in semver format (e.g., 1.0.0)'),
  lastUpdated: z.string().datetime(),
  commands: z.array(CommandSchema),
  skills: z.array(SkillSchema),
  agents: z.array(AgentSchema),
  scripts: z.array(ScriptSchema),
  documentations: z.array(DocumentationSchema),
});

// ============================================================================
// Types
// ============================================================================

type Command = z.infer<typeof CommandSchema>;
type Skill = z.infer<typeof SkillSchema>;
type Agent = z.infer<typeof AgentSchema>;
type Script = z.infer<typeof ScriptSchema>;
type Documentation = z.infer<typeof DocumentationSchema>;
type CommandResourceRegistry = z.infer<typeof CommandResourceRegistrySchema>;

// ============================================================================
// Validation Functions
// ============================================================================

/**
 * Validate relationship integrity
 * Ensures all references (Command.relatedSkills → Skill.id) are valid
 */
function validateRelationships(registry: CommandResourceRegistry): string[] {
  const errors: string[] = [];

  const skillIds = new Set(registry.skills.map((s) => s.id));
  const agentIds = new Set(registry.agents.map((a) => a.id));
  const scriptIds = new Set(registry.scripts.map((s) => s.id));
  const commandIds = new Set(registry.commands.map((c) => c.id));

  // Validate Command.relatedSkills
  registry.commands.forEach((cmd) => {
    cmd.relatedSkills?.forEach((skillId) => {
      if (!skillIds.has(skillId)) {
        errors.push(`Command "${cmd.id}" references non-existent skill "${skillId}"`);
      }
    });

    cmd.relatedAgents?.forEach((agentId) => {
      if (!agentIds.has(agentId)) {
        errors.push(`Command "${cmd.id}" references non-existent agent "${agentId}"`);
      }
    });

    cmd.relatedScripts?.forEach((scriptId) => {
      const scriptIdNormalized = path.basename(scriptId, '.sh');
      if (!scriptIds.has(scriptIdNormalized) && !scriptIds.has(scriptId)) {
        errors.push(`Command "${cmd.id}" references non-existent script "${scriptId}"`);
      }
    });
  });

  // Validate Skill.usedByCommands
  registry.skills.forEach((skill) => {
    skill.usedByCommands?.forEach((cmdId) => {
      if (!commandIds.has(cmdId)) {
        errors.push(`Skill "${skill.id}" references non-existent command "${cmdId}"`);
      }
    });
  });

  // Validate Agent.usedByCommands
  registry.agents.forEach((agent) => {
    agent.usedByCommands?.forEach((cmdId) => {
      if (!commandIds.has(cmdId)) {
        errors.push(`Agent "${agent.id}" references non-existent command "${cmdId}"`);
      }
    });
  });

  return errors;
}

/**
 * Validate file existence
 * Ensures all referenced files/directories actually exist
 */
function validateFileExistence(registry: CommandResourceRegistry): string[] {
  const errors: string[] = [];

  registry.commands.forEach((cmd) => {
    if (!fs.existsSync(cmd.filePath)) {
      errors.push(`Command file not found: ${cmd.filePath}`);
    }
  });

  registry.skills.forEach((skill) => {
    if (!fs.existsSync(skill.directoryPath)) {
      errors.push(`Skill directory not found: ${skill.directoryPath}`);
    }
  });

  registry.agents.forEach((agent) => {
    if (!fs.existsSync(agent.directoryPath)) {
      errors.push(`Agent directory not found: ${agent.directoryPath}`);
    }
  });

  registry.scripts.forEach((script) => {
    if (!fs.existsSync(script.filePath)) {
      errors.push(`Script file not found: ${script.filePath}`);
    }
  });

  return errors;
}

/**
 * Validate uniqueness constraints
 */
function validateUniqueness(registry: CommandResourceRegistry): string[] {
  const errors: string[] = [];

  const commandIds = registry.commands.map((c) => c.id);
  const duplicateCommands = commandIds.filter((id, index) => commandIds.indexOf(id) !== index);
  if (duplicateCommands.length > 0) {
    errors.push(`Duplicate command IDs found: ${duplicateCommands.join(', ')}`);
  }

  const skillIds = registry.skills.map((s) => s.id);
  const duplicateSkills = skillIds.filter((id, index) => skillIds.indexOf(id) !== index);
  if (duplicateSkills.length > 0) {
    errors.push(`Duplicate skill IDs found: ${duplicateSkills.join(', ')}`);
  }

  return errors;
}

// ============================================================================
// Main
// ============================================================================

function main() {
  const args = process.argv.slice(2);

  if (args.length === 0) {
    console.error('Usage: node validate-registry-schema.ts <registry-file.json>');
    process.exit(1);
  }

  const registryPath = args[0];

  if (!fs.existsSync(registryPath)) {
    console.error(`Error: Registry file not found: ${registryPath}`);
    process.exit(1);
  }

  try {
    // Read and parse JSON
    const registryData = JSON.parse(fs.readFileSync(registryPath, 'utf-8'));

    // Validate schema
    console.log('🔍 Validating schema...');
    const result = CommandResourceRegistrySchema.safeParse(registryData);

    if (!result.success) {
      console.error('❌ Schema validation failed:');
      result.error.errors.forEach((err) => {
        console.error(`  - ${err.path.join('.')}: ${err.message}`);
      });
      process.exit(1);
    }

    const registry = result.data;

    // Validate relationships
    console.log('🔗 Validating relationships...');
    const relationshipErrors = validateRelationships(registry);
    if (relationshipErrors.length > 0) {
      console.error('❌ Relationship validation failed:');
      relationshipErrors.forEach((err) => console.error(`  - ${err}`));
      process.exit(1);
    }

    // Validate file existence
    console.log('📁 Validating file existence...');
    const fileErrors = validateFileExistence(registry);
    if (fileErrors.length > 0) {
      console.error('⚠️  File existence warnings:');
      fileErrors.forEach((err) => console.warn(`  - ${err}`));
      // Don't exit on file errors (warnings only)
    }

    // Validate uniqueness
    console.log('🔢 Validating uniqueness constraints...');
    const uniquenessErrors = validateUniqueness(registry);
    if (uniquenessErrors.length > 0) {
      console.error('❌ Uniqueness validation failed:');
      uniquenessErrors.forEach((err) => console.error(`  - ${err}`));
      process.exit(1);
    }

    // Success
    console.log('✅ Registry validation passed!');
    console.log(`  Commands: ${registry.commands.length}`);
    console.log(`  Skills: ${registry.skills.length}`);
    console.log(`  Agents: ${registry.agents.length}`);
    console.log(`  Scripts: ${registry.scripts.length}`);
    process.exit(0);
  } catch (error) {
    console.error('❌ Validation error:', error instanceof Error ? error.message : String(error));
    process.exit(1);
  }
}

main();
