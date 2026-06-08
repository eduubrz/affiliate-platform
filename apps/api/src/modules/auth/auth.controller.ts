import { Request, Response } from "express";
import { z } from "zod";
import { authService } from "./auth.service";
import { asyncHandler } from "../../shared/utils/asyncHandler";

export class AuthController {
  register = asyncHandler(async (req: Request, res: Response) => {
    const dto = z.object({
      email: z.string().email(),
      password: z.string().min(8),
      name: z.string().min(2),
    }).parse(req.body);
    const result = await authService.register(dto);
    res.status(201).json({ success: true, data: result });
  });

  login = asyncHandler(async (req: Request, res: Response) => {
    const dto = z.object({
      email: z.string().email(),
      password: z.string().min(1),
    }).parse(req.body);
    const result = await authService.login(dto);
    res.cookie("refreshToken", result.tokens.refreshToken, {
      httpOnly: true,
      secure: process.env.NODE_ENV === "production",
      sameSite: "strict",
      maxAge: 30 * 24 * 60 * 60 * 1000,
    });
    res.json({ success: true, data: { user: result.user, accessToken: result.tokens.accessToken } });
  });

  refresh = asyncHandler(async (req: Request, res: Response) => {
    const token = (req as any).cookies?.refreshToken || req.body.refreshToken;
    if (!token) return res.status(401).json({ error: "Refresh token required" });
    const tokens = await authService.refreshToken(token);
    res.cookie("refreshToken", tokens.refreshToken, {
      httpOnly: true,
      secure: process.env.NODE_ENV === "production",
      sameSite: "strict",
      maxAge: 30 * 24 * 60 * 60 * 1000,
    });
    res.json({ success: true, data: { accessToken: tokens.accessToken } });
  });

  logout = asyncHandler(async (req: Request, res: Response) => {
    const token = (req as any).cookies?.refreshToken || req.body.refreshToken;
    if (token) await authService.logout(token);
    res.clearCookie("refreshToken");
    res.json({ success: true, message: "Logged out" });
  });

  me = asyncHandler(async (req: Request, res: Response) => {
    const user = await authService.getMe(req.user!.id);
    res.json({ success: true, data: user });
  });
}

export const authController = new AuthController();
