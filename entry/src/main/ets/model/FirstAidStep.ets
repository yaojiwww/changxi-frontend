/** 急救培训的单个步骤 */

/** 该步骤要求用户做出的交互动作 */
export enum ActionType {
  TAP = 'TAP',
  LONG_PRESS = 'LONG_PRESS',
  DRAG = 'DRAG'
}

export interface FirstAidStep {
  id: string;
  title: string;
  description: string;
  actionType: ActionType;
}
