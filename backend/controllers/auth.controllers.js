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

// =========================================================
// REGISTER
// =========================================================

async function register(req, res, next) {
  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();

    const { full_name, phone, email, password, role, restaurant_name, address } = req.body;

    if (!phone || !password || !role || !full_name) {
      return res.status(400).json({
        success: false,
        message: "الرجاء إدخال الحقول الإجبارية (الاسم، الهاتف، كلمة المرور، والدور)"
      });
    }

    // التحقق هل رقم الهاتف مسجل مسبقاً
    const [existingUsers] = await connection.execute(
      `SELECT id FROM users WHERE phone = ? LIMIT 1`,
      [phone]
    );

    if (existingUsers.length > 0) {
      return res.status(400).json({
        success: false,
        message: "رقم الهاتف مستخدم بالفعل"
      });
    }

    // تشفير كلمة المرور
    const saltRounds = 10;
    const passwordHash = await bcrypt.hash(password, saltRounds);

    // إدخال المستخدم في جدول users الأساسي
    const [userResult] = await connection.execute(
      `INSERT INTO users (full_name, phone, email, password_hash, role, is_active) VALUES (?, ?, ?, ?, ?, 1)`,
      [full_name, phone, email || null, passwordHash, role]
    );

    const userId = userResult.insertId;

    // إذا كان المستخدم مطعماً، نقوم بإضافته لجدول المطاعم
    if (role === 'restaurant') {
      await connection.execute(
        `INSERT INTO restaurants (user_id, name, address, is_open) VALUES (?, ?, ?, 1)`,
        [userId, restaurant_name || full_name, address || 'غير محدد']
      );
    } 
    // إذا كان المستخدم سائقاً، نقوم بإضافته لجدول السائقين
    else if (role === 'driver') {
      await connection.execute(
        `INSERT INTO drivers (user_id, is_available) VALUES (?, 1)`,
        [userId]
      );
    }

    await connection.commit();

    return res.status(201).json({
      success: true,
      message: "تم إنشاء الحساب بنجاح"
    });

  } catch (error) {
    await connection.rollback();
    next(error);
  } finally {
    connection.release();
  }
}

module.exports = {
  login,
  register
};
