// interactionTypes.ets
export enum ActionType {
  TAP,
  LONG_PRESS
}

export interface FirstAidStep {
  id: string;
  title: string;
  description: string;
  actionType: ActionType;
}