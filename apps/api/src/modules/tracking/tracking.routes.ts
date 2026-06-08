import { Router, Request, Response } from "express";

const router = Router();

router.get("/:code", async (req: Request, res: Response) => {
  res.redirect(301, "https://shopee.com.br");
});

export default router;
