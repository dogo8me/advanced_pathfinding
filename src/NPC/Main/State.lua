export type StateEnum = "PATROLLING" | "SEARCHING" | "CHASING"

export type State = {
	targetNode: BasePart?,
	state: StateEnum,
}

export type soundAction = "RUNNING" | "WALKING"

local State = {
	targetNode = nil,
	state = "PATROLLING",
} :: State

return State
