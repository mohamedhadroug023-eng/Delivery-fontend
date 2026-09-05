const bcrypt = require("bcrypt");
const pool = require("../config/database");
const generateToken = require("../utils/generateToken");

// =========================================================
// LOGIN
// =========================================================

async function login(req, res, next) {
  try {
    const { phone, password } = req.body;

    if (!phone || !password) {
      return res.status(400).json({
        success: false,
        message: "Phone and password are required"
      });
    }

    const [users] = await pool.execute(
      `
      SELECT id, full_name, phone, email, password_hash, role, is_active
      FROM users
      WHERE phone = ?
      LIMIT 1
      `,
      [phone]
    );

    if (users.length === 0) {
      return res.status(401).json({
        success: false,
        message: "Invalid phone or password"
      });
    }

    const user = users[0];

    if (!user.is_active) {
      return res.status(403).json({
        success: false,
        message: "Account is disabled"
      });
    }

    const passwordValid = await bcrypt.compare(
      password,
      user.password_hash
    );

    if (!passwordValid) {
      return res.status(401).json({
        success: false,
        message: "Invalid phone or password"
      });
    }

    const token = generateToken(user);

    return res.status(200).json({
      success: true,
      message: "Login successful",
      token,
      user: {
        id: user.id,
        full_name: user.full_name,
        phone: user.phone,
        email: user.email,
        role: user.role
      }
    });

  } catch (error) {
    next(error);
  }
}

module.exports = {
  login
};
