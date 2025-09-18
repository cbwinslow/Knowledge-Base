export type ScriptItem = { id:string; name:string; category:string; description:string; tags:string[]; ports?:number[]; script_bash:string; script_ansible:string; terraform?:string; pulumi?:string }
export type Bundle = { id: string; name: string; description: string; itemIds: string[] }
