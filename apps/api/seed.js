const bcrypt = require("bcryptjs");
const { PrismaClient } = require("@prisma/client");
const prisma = new PrismaClient();

async function main() {
  const hash = await bcrypt.hash("senha123", 12);
  const user = await prisma.user.create({
    data: {
      email: "admin@affiliateos.com",
      passwordHash: hash,
      name: "Admin",
      role: "SUPER_ADMIN"
    }
  });
  console.log("Usuario criado:", user.email);
  await prisma.$disconnect();
}

main().catch(console.error);
