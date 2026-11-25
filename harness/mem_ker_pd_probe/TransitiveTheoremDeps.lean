import Lean

open Lean

private def isProjectModule (moduleName : Name) : Bool :=
  let name := moduleName.toString
  ["BuildAid", "CompanionTheory", "Development", "Formalism", "GroundTheory",
    "Lemmata", "PositivityTheory", "ReciprocityTheory", "Supplements", "Statements", "Main"].any
    fun pfx => name == pfx || name.startsWith (pfx ++ ".")

private def rangeOwner? (env : Environment) (name : Name) : Option (Name × DeclarationRanges) := Id.run do
  let mut current := name
  while !current.isAnonymous do
    if let some range := declRangeExt.find? (level := .server) env current then
      return some (current, range)
    current := current.getPrefix
  return none

private def transitiveConstants (env : Environment) (root : Name) :
    Array (Name × Name × Name × Nat × Nat × Bool) := Id.run do
  let mut seen : NameSet := {}
  let mut pending := [root]
  let mut constants := #[]
  while let name :: rest := pending do
    pending := rest
    if seen.contains name then
      continue
    seen := seen.insert name
    let some info := env.find? name | continue
    let some index := env.getModuleIdxFor? name | continue
    let moduleName := env.header.moduleNames[index]!
    if !isProjectModule moduleName then
      continue
    let owner := rangeOwner? env name
    let ownerName := owner.map (·.1) |>.getD Name.anonymous
    let startLine := owner.map (·.2.range.pos.line) |>.getD 0
    let endLine := owner.map (·.2.range.endPos.line) |>.getD 0
    let isTheorem := match info with
      | .thmInfo _ => true
      | _ => false
    constants := constants.push (name, moduleName, ownerName, startLine, endLine, isTheorem)
    pending := info.getUsedConstantsAsSet.toList ++ pending
  return constants

def main (args : List String) : IO Unit := do
  let [moduleString, theoremString] := args
    | throw <| IO.userError "usage: lean --run TransitiveTheoremDeps.lean MODULE THEOREM"
  let moduleName := moduleString.toName
  let theoremName := theoremString.toName
  let env ← importModules #[{ module := moduleName }] {}
  unless (env.find? theoremName).isSome do
    throw <| IO.userError s!"theorem not found: {theoremName}"
  for (name, sourceModule, owner, startLine, endLine, isTheorem) in transitiveConstants env theoremName do
    IO.println s!"{name}\t{sourceModule}\t{owner}\t{startLine}\t{endLine}\t{isTheorem}"
