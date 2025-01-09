const functions = require("firebase-functions");
const nodemailer = require("nodemailer");
const admin = require("firebase-admin");
admin.initializeApp();

const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: "your-email@gmail.com",
    pass: "your-email-password",
  },
});

exports.sendEmailOtp = functions.https.onCall(async (data, context) => {
  const email = data.email;
  const otp = Math.floor(100000 + Math.random() * 900000).toString();

  const mailOptions = {
    from: "your-email@gmail.com",
    to: email,
    subject: "Your OTP Code",
    text: `Your OTP code is ${otp}`,
  };

  try {
    await transporter.sendMail(mailOptions);

    await admin.firestore().collection("otps").add({
      email: email,
      otp: otp,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {success: true};
  } catch (error) {
    console.error("Error sending email or saving OTP:", error);
    throw new functions.https.HttpsError("internal", "Unable to send OTP");
  }
});

exports.verifyEmailOtp = functions.https.onCall(async (data, context) => {
  const email = data.email;
  const otp = data.otp;

  try {
    const otps = await admin.firestore().collection("otps")
        .where("email", "==", email)
        .orderBy("createdAt", "desc")
        .limit(1)
        .get();

    if (otps.empty) {
      return {success: false, message: "No OTP found"};
    }

    const otpDoc = otps.docs[0];

    if (otpDoc.data().otp === otp) {
      await otpDoc.ref.delete(); // Optionally delete the OTP after verification
      return {success: true};
    } else {
      return {success: false, message: "Invalid OTP"};
    }
  } catch (error) {
    console.error("Error verifying OTP:", error);
    throw new functions.https.HttpsError("internal", "Unable to verify OTP");
  }
});
