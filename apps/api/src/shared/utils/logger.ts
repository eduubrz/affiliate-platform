import winston from "winston";

const { combine, timestamp, colorize, printf } = winston.format;

const devFormat = printf(({ level, message, timestamp }) => {
  return ${timestamp} [${level}]: ${message};
});

export const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || "info",
  format: combine(
    timestamp({ format: "YYYY-MM-DD HH:mm:ss" }),
    process.env.NODE_ENV === "production"
      ? winston.format.json()
      : combine(colorize(), devFormat)
  ),
  transports: [
    new winston.transports.Console(),
    new winston.transports.File({ filename: "logs/error.log", level: "error" }),
    new winston.transports.File({ filename: "logs/combined.log" }),
  ],
});
