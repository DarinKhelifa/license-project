let nodemailer = null;

try {
  nodemailer = require('nodemailer');
} catch (error) {
  console.warn('nodemailer is not installed. OTP emails will be disabled until dependencies are installed.');
}

// Create transporter based on environment variables
const createTransporter = () => {
  if (!nodemailer) {
    return null;
  }

  // For Gmail
  if (process.env.SMTP_HOST === 'smtp.gmail.com') {
    return nodemailer.createTransport({
      service: 'gmail',
      auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_PASS,
      },
    });
  }
  
  // For other SMTP providers
  return nodemailer.createTransport({
    host: process.env.SMTP_HOST,
    port: parseInt(process.env.SMTP_PORT) || 587,
    secure: process.env.SMTP_SECURE === 'true',
    auth: {
      user: process.env.EMAIL_USER,
      pass: process.env.EMAIL_PASS,
    },
  });
};

const transporter = createTransporter();

const sendOTPEmail = async ({ email, name, otp }) => {
  try {
    if (!transporter) {
      console.warn(`Skipping OTP email to ${email} because the mail transporter is unavailable.`);
      return false;
    }

    const info = await transporter.sendMail({
      from: `"ORELAX" <${process.env.EMAIL_FROM || process.env.EMAIL_USER}>`,
      to: email,
      subject: 'Verify Your ORELAX Account',
      html: `
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
        </head>
        <body style="margin: 0; padding: 0; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f4f4;">
          <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #f4f4f4; padding: 40px 0;">
            <tr>
              <td align="center">
                <table width="500" cellpadding="0" cellspacing="0" style="background-color: #ffffff; border-radius: 12px; box-shadow: 0 4px 12px rgba(0,0,0,0.1); overflow: hidden;">
                  <!-- Header -->
                  <tr>
                    <td style="background-color: #034808; padding: 30px 20px; text-align: center;">
                      <h1 style="color: #FFD700; margin: 0; font-size: 32px;">ORELAX</h1>
                      <p style="color: #ffffff; margin: 8px 0 0;">Smart · Safe · Comfortable</p>
                    </td>
                  </tr>
                  
                  <!-- Content -->
                  <tr>
                    <td style="padding: 30px 25px;">
                      <h2 style="color: #034808; margin-top: 0;">Welcome to ORELAX, ${name}!</h2>
                      <p style="color: #555555; line-height: 1.6; font-size: 16px;">
                        Thank you for joining our community. Please use the verification code below to complete your registration.
                        This code will expire in <strong>15 minutes</strong>.
                      </p>
                      
                      <!-- OTP Code Box -->
                      <div style="background-color: #f0f0f0; padding: 20px; text-align: center; border-radius: 8px; margin: 25px 0;">
                        <span style="font-size: 36px; font-weight: bold; letter-spacing: 8px; color: #034808;">${otp}</span>
                      </div>
                      
                      <p style="color: #555555; line-height: 1.6;">
                        If you didn't request this verification, please ignore this email.
                      </p>
                      
                      <hr style="border: none; border-top: 1px solid #e0e0e0; margin: 25px 0;">
                      
                      <p style="color: #888888; font-size: 12px; text-align: center; margin: 0;">
                        &copy; ${new Date().getFullYear()} ORELAX. All rights reserved.
                      </p>
                    </td>
                  </tr>
                </table>
              </td>
            </tr>
          </table>
        </body>
        </html>
      `,
    });

    console.log(`✅ OTP email sent to ${email}. Message ID: ${info.messageId}`);
    return true;
  } catch (error) {
    console.error('❌ Email sending failed:', error);
    return false;
  }
};

module.exports = { sendOTPEmail };