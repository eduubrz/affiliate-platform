import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import { prisma } from "../../config/database";
import { env } from "../../config/env";
import { AppError } from "../../shared/utils/AppError";
import { logger } from "../../shared/utils/logger";

export class AuthService {
  async register(dto: { email: string; password: string; name: string }) {
    const existing = await prisma.user.findUnique({ where: { email: dto.email } });
    if (existing) throw new AppError("Email already in use", 409);
    const passwordHash = await bcrypt.hash(dto.password, 12);
    const user = await prisma.user.create({
      data: { email: dto.email.toLowerCase().trim(), passwordHash, name: dto.name.trim() },
    });
    const tokens = await this.generateTokens(user.id);
    const { passwordHash: _ph, ...safeUser } = user;
    return { user: safeUser, tokens };
  }

  async login(dto: { email: string; password: string }) {
    const user = await prisma.user.findUnique({ where: { email: dto.email.toLowerCase() } });
    if (!user || !user.isActive) throw new AppError("Invalid credentials", 401);
    const match = await bcrypt.compare(dto.password, user.passwordHash);
    if (!match) throw new AppError("Invalid credentials", 401);
    await prisma.user.update({ where: { id: user.id }, data: { lastLoginAt: new Date() } });
    const tokens = await this.generateTokens(user.id);
    logger.info(`User logged in: ${user.email}`);
    const { passwordHash: _ph, ...safeUser } = user;
    return { user: safeUser, tokens };
  }

  async refreshToken(token: string) {
    const stored = await prisma.refreshToken.findUnique({ where: { token } });
    if (!stored || stored.revokedAt || stored.expiresAt < new Date()) {
      throw new AppError("Invalid or expired refresh token", 401);
    }
    await prisma.refreshToken.update({ where: { id: stored.id }, data: { revokedAt: new Date() } });
    return this.generateTokens(stored.userId);
  }

  async logout(refreshToken: string) {
    await prisma.refreshToken.updateMany({
      where: { token: refreshToken },
      data: { revokedAt: new Date() },
    });
  }

  async getMe(userId: string) {
    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new AppError("User not found", 404);
    const { passwordHash: _ph, ...safeUser } = user;
    return safeUser;
  }

  private async generateTokens(userId: string) {
    const accessToken = jwt.sign({ sub: userId }, env.JWT_ACCESS_SECRET, {
      expiresIn: env.JWT_ACCESS_EXPIRES,
    });
    const refreshToken = jwt.sign({ sub: userId }, env.JWT_REFRESH_SECRET, {
      expiresIn: env.JWT_REFRESH_EXPIRES,
    });
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 30);
    await prisma.refreshToken.create({ data: { token: refreshToken, userId, expiresAt } });
    return { accessToken, refreshToken };
  }
}

export const authService = new AuthService();
