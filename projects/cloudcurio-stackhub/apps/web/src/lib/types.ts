export type ScriptItem = {
  id: string
  name: string
  category: string
  description: string
  tags: string[]
  script_bash: string
  script_ansible: string
  terraform?: string
  pulumi?: string
}
