// 导出管理类和服务类
export { TokenManager } from './tokenManager';
export { ApiService } from './apiService';

// 导出接口定义
export type {
  SendCodeRequest,
  SendCodeResponse,
  RegisterRequest,
  RegisterResponse,
  LoginRequest,
  LoginResponse,
  LogoutRequest,
  LogoutResponse,
  ChatRequest,
  ChatResponseData, // 把这里改为 ChatResponseData
  UserData
} from './apiTypes';