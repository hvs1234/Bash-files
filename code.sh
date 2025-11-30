#!/bin/bash

cat > .vscode/settings.json << 'EOF'
{
  "material-icon-theme.folders.associations": {
    "global_component": "global",
    "global_components": "global",
    "globalComponent": "global",
    "globalComponents": "global",
    "globalService": "robot",
    "globalServices": "robot",
    "shared_component": "components",
    "shared_components": "components",
    "sharedComponents": "components",
    "sharedComponent": "components",
    "ui_elements": "components",
    "ui_element": "components",
    "uiElements": "components",
    "uiElement": "components",
    "widgets": "components",
    "btns": "ui"
  }
}
EOF

cat > src/App.jsx << 'EOF'
/* eslint-disable react/prop-types */
import {
  BrowserRouter,
  Routes,
  Route,
  useLocation,
  Navigate,
} from "react-router-dom";
import AppRoutes from "./AppRoutes";
import Header from "./globalComponents/Header";
import Footer from "./globalComponents/Footer";
import { ToastContainer } from "react-toastify";

const Layout = ({ children }) => {
  const { pathname } = useLocation();
  const hideLayout = pathname === "/auth";

  return (
    <div className="relative flex flex-col w-full min-h-screen">
      <ToastContainer
        className={`custom-toast-container`}
        autoClose={3000}
        position="bottom-right"
      />
      {!hideLayout && <Header />}
      <div className="flex-1 w-full">{children}</div>
      {!hideLayout && <Footer />}
    </div>
  );
};

const App = () => {
  return (
    <BrowserRouter>
      <Layout>
        <Routes>
          <Route path="/" element={<Navigate to="/default" />} />
          {AppRoutes.map((r, i) => {
            const Component = r.component;
            return <Route key={i} path={r.path} element={<Component />} />;
          })}
        </Routes>
      </Layout>
    </BrowserRouter>
  );
};

export default App;
EOF

cat > src/AppRoutes.js << 'EOF'
import Default from "./Default";
import Auth from "./features/auth/pages/Auth";

const AppRoutes = [
  { path: "/auth", component: Auth },
  { path: "/default", component: Default },
];

export default AppRoutes;
EOF

cat > src/ProtectedRoute.js << 'EOF'
/* eslint-disable no-unused-vars */
/* eslint-disable react/prop-types */
import React, { useEffect } from "react";
import { useSelector, useDispatch } from "react-redux";
import { Navigate, useNavigate } from "react-router-dom";
import { toast, ToastContainer } from "react-toastify";
import {
  setIsAuthenticated,
  setLoadingUserInfo,
} from "./features/auth/services/toolkit/AuthSlice";
import { BiLoaderAlt } from "react-icons/bi";

const ProtectedRoute = ({ children }) => {
  const dispatch = useDispatch();
  const navigate = useNavigate();
  const {
    isAuthenticated,
    loadingUserInfo,
    userInfo: user,
  } = useSelector((s) => s.authApp);

  useEffect(() => {
    const check = async () => {
      try {
        dispatch(setIsAuthenticated(true));
      } catch (err) {
        dispatch(setIsAuthenticated(false));
        toast.error("Session expired");
        setTimeout(() => navigate("/auth"), 3000);
      } finally {
        dispatch(setLoadingUserInfo(false));
      }
    };
    if (loadingUserInfo) check();
  }, [loadingUserInfo]);

  if (loadingUserInfo)
    return (
      <>
        <ToastContainer
          autoClose={2000}
          position="bottom-right"
          className="custom-toast-container"
        />
        <div className="w-auto h-screen flex items-center justify-center bg-white">
          <BiLoaderAlt size={60} className={`text-[blue] animate-spin`} />
        </div>
      </>
    );

  if (!isAuthenticated)
    return (
      <>
        <ToastContainer
          autoClose={2000}
          position="bottom-right"
          className="custom-toast-container"
        />
        <div className="w-auto h-screen flex items-center justify-center bg-white"></div>
      </>
    );

  return (
    <>
      <ToastContainer
        autoClose={2000}
        position="bottom-right"
        className="custom-toast-container"
      />
      {children}
    </>
  );
};

export default ProtectedRoute;
EOF

cat > src/features/auth/services/toolkit/AuthSlice.js << 'EOF'
/* eslint-disable no-unused-vars */
import { createSlice } from "@reduxjs/toolkit";

const initialState = {
  isAuthenticated: false,
  isLogin: false,
  isSignup: false,
  isLogout: false,
  loadingUserInfo: true,
  selectRole: "admin",
  userInfo: null,
  userMode: "login",
  username: "",
  password: "",
  createUsername: "",
  createEmail: "",
  createPassword: "",
};

const Slice = createSlice({
  name: "authApp",
  initialState,
  reducers: {
    setIsAuthenticated: (s, a) => {
      s.isAuthenticated = a.payload;
    },
    setIsLogin: (s, a) => {
      s.isLogin = a.payload;
    },
    setIsSignup(s, a) {
      s.isSignup = a.payload;
    },
    setIsLogout(s, a) {
      s.isLogout = a.payload;
    },
    setLoadingUserInfo(s, a) {
      s.loadingUserInfo = a.payload;
    },
    setSelectRole(s, a) {
      s.selectRole = a.payload;
    },
    setUserInfo(s, a) {
      s.userInfo = a.payload;
    },
    setUserMode: (s, a) => {
      s.userMode = a.payload;
    },
    setUsername: (s, a) => {
      s.username = a.payload;
    },
    setPassword: (s, a) => {
      s.password = a.payload;
    },
    setCreateUsername: (s, a) => {
      s.createUsername = a.payload;
    },
    setCreateEmail: (s, a) => {
      s.createEmail = a.payload;
    },
    setCreatePassword: (s, a) => {
      s.createPassword = a.payload;
    },
  },
});

export const {
  setIsAuthenticated,
  setIsLogin,
  setIsSignup,
  setIsLogout,
  setLoadingUserInfo,
  setSelectRole,
  setUserInfo,
  setUserMode,
  setCreatePassword,
  setCreateUsername,
  setUsername,
  setCreateEmail,
  setPassword,
} = Slice.actions;

export default Slice.reducer;
EOF

cat > src/features/auth/services/toolkit/AuthHandlers.js << 'EOF'
/* eslint-disable no-unused-vars */
import { toast } from "react-toastify";
import {
  setIsAuthenticated,
  setIsLogin,
  setIsLogout,
  setIsSignup,
} from "./AuthSlice";

export const handleLogin =
  ({ username, password }) =>
  async (dispatch) => {
    try {
      const fields = { username, password };
      const empty = Object.keys(fields).filter((k) => !fields[k]);
      if (empty.length) {
        toast.warn(`Required ${empty.join(" and ")}`);
        return;
      }

      dispatch(setIsLogin(true));
      dispatch(setIsAuthenticated(true));
    } catch (err) {
      toast.error("Something went wrong while login!");
      dispatch(setIsAuthenticated(false));
    } finally {
      dispatch(setIsLogin(false));
    }
  };

export const handleSignup =
  ({ createUsername, createEmail, createPassword }) =>
  async (dispatch) => {
    try {
      const fields = { createUsername, createEmail, createPassword };
      const empty = Object.keys(fields).filter((k) => !fields[k]);
      if (empty.length) {
        toast.warn(`Required ${empty.join(" and ")}`);
        return;
      }
      dispatch(setIsSignup(true));
    } catch (err) {
      toast.error("Something went wrong while signup!");
    } finally {
      dispatch(setIsSignup(false));
    }
  };

export const handleLogout = () => async (dispatch) => {
  try {
    dispatch(setIsLogout(true));
    dispatch(setIsAuthenticated(false));
    toast.success("Logged out successfully");
  } catch (err) {
    toast.error("Something went wrong while logout!");
  } finally {
    dispatch(setIsLogout(false));
  }
};
EOF

cat > src/utils/Store.js << 'EOF'
import { configureStore } from "@reduxjs/toolkit";
import authReducer from "../features/auth/services/toolkit/AuthSlice";
import globalReducer from "../globalService/GlobalSlice";

export const store = configureStore({
  reducer: {
    authApp: authReducer,
    globalApp: globalReducer,
  },
});
EOF

cat > src/main.jsx << 'EOF'
/* eslint-disable no-unused-vars */
import { createRoot } from "react-dom/client";
import "./index.css";
import App from "./App.jsx";
import { Provider } from "react-redux";
import { store } from "./utils/Store.js";

createRoot(document.getElementById("root")).render(
  <Provider store={store}>
    <App />
  </Provider>
);
EOF

cat > src/globalService/GlobalSlice.js << 'EOF'
/* eslint-disable no-unused-vars */
import { createSlice } from "@reduxjs/toolkit";

const initialState = {
  isMenuOpen: false,
};

const Slice = createSlice({
  name: "globalApp",
  initialState,
  reducers: {
    setMenuOpen: (state, action) => {
      state.isMenuOpen = action.payload;
    },
  },
});

export const { setMenuOpen } = Slice.actions;
export default Slice.reducer;
EOF

cat > src/Default.jsx << 'EOF'
/* eslint-disable no-unused-vars */
import React from "react";
import { GiRobotGolem } from "react-icons/gi";

const Default = () => {
  return (
    <>
      <div
        className={`w-full h-screen bg-[#d7fff3] flex gap-8 items-center justify-center text-center`}
      >
        <GiRobotGolem
          size={60}
          className={`text-2xl animate-bounce text-[#414141]`}
        />
        <h1 className={`text-4xl font-extrabold text-[#5959ad]`}>
          Welcome to Hvs Great App
        </h1>
        <GiRobotGolem
          size={60}
          className={`text-2xl animate-bounce text-[#414141]`}
        />
      </div>
    </>
  );
};

export default Default;
EOF

cat > src/globalComponents/btns/ViewBtn.jsx << 'EOF'
/* eslint-disable no-unused-vars */
/* eslint-disable react/prop-types */
import React from "react";

const ViewBtn = ({
  btnTitle,
  btnClass,
  btnFunc,
  disabled = false,
  view,
  btnType,
}) => {
  return (
    <>
      <button
        onClick={btnFunc}
        disabled={disabled}
        className={`px-8 py-4 ${
          view === "auto" ? "w-auto" : "w-full"
        } text-[white] font-extrabold transition-all duration-200 rounded-xl ease-in-out hover:opacity-[0.8] bg-[#5454b1] text-xl ${btnClass} ${
          disabled ? "cursor-not-allowed opacity-50" : "cursor-pointer"
        } ${btnType ? "opacity-[1]" : "opacity-[0.6]"}`}
      >
        {btnTitle}
      </button>
    </>
  );
};

export default ViewBtn;
EOF

cat > src/globalComponents/Header.jsx << 'EOF'
/* eslint-disable no-unused-vars */
import { useEffect, useRef, useState } from "react";
import { Link } from "react-router-dom";
import { HiMenuAlt1 } from "react-icons/hi";
import { NavLink } from "../globalService/Data";

const Header = () => {
  const [navlink] = useState(NavLink);
  const [isMenuOpen, setIsMenuOpen] = useState(false);
  const [view, setView] = useState("Home");
  const sidebarRef = useRef(null);
  const [scrollingUp, setScrollingUp] = useState(false);
  const prevScrollY = useRef(0);
  const [isDropdownOpen, setIsDropdownOpen] = useState(null);
  const [isMobileDropdownOpen, setIsMobileDropdownOpen] = useState(null);
  const dropdownRef = useRef(null);

  const toggleMenu = () => setIsMenuOpen(!isMenuOpen);
  const handleNavigation = () => {
    window.scrollTo(0, 0);
    setIsMenuOpen(false);
    setIsDropdownOpen(null);
    setIsMobileDropdownOpen(null);
  };

  const handleSelectedView = (selectedView) => {
    setView(selectedView);
  };

  useEffect(() => {
    const handleScroll = () => {
      const currentScrollY = window.scrollY;
      setScrollingUp(currentScrollY < prevScrollY.current);
      prevScrollY.current = currentScrollY;
    };

    window.addEventListener("scroll", handleScroll);
    return () => window.removeEventListener("scroll", handleScroll);
  }, []);

  useEffect(() => {
    const handleClickOutside = (event) => {
      if (
        sidebarRef.current &&
        !sidebarRef.current.contains(event.target) &&
        isMenuOpen
      ) {
        setIsMenuOpen(false);
      }
      if (dropdownRef.current && !dropdownRef.current.contains(event.target)) {
        setIsDropdownOpen(null);
        setIsMobileDropdownOpen(null);
      }
    };

    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, [isMenuOpen]);

  return (
    <>
      <div
        className={`header fixed top-0 left-0 z-200 px-6 py-6 shadow-sm flex justify-center 
        items-center gap-10 w-full max-lg:justify-end`}
        ref={sidebarRef}
      >
        <div
          className={`absolute top-0 left-0 w-full h-full bg-[crimson] transition-all duration-[0.4s] ease-linear opacity-100`}
        ></div>
        <nav className="relative navbar w-auto hidden lg:flex">
          <ul className="flex items-start gap-16 transition-all duration-200 ease-in-out">
            {navlink.map((e) => {
              if (e.submenu) {
                return (
                  <div
                    key={e.id}
                    className="relative cursor-pointer"
                    onMouseEnter={() => setIsDropdownOpen(e.id)}
                    onMouseLeave={() => setIsDropdownOpen(null)}
                  >
                    <span
                      className={`navlink border-b pb-2 border-none text-xl text-white max-md:text-xl font-semibold  transition-all duration-200 navlink tracking-[0] hover:opacity-50`}
                    >
                      {e.title} &nbsp;
                      <i className="fa-solid fa-chevron-down text-sm relative bottom-[0.2rem]"></i>
                    </span>
                    {isDropdownOpen === e.id && (
                      <div
                        ref={dropdownRef}
                        className="absolute -left-24 mt-[0.2rem] px-4 py-4 border border-[#d2d2d2] w-[300px] 
                        bg-white shadow-lg rounded-lg z-50 flex flex-col gap-2"
                      >
                        {e.submenu.map((sub) => (
                          <Link
                            key={sub.id}
                            to={sub.to}
                            className="block text-lg hover:opacity-50 text-black transition"
                            onClick={handleNavigation}
                          >
                            {sub.title}
                          </Link>
                        ))}
                      </div>
                    )}
                  </div>
                );
              } else {
                return (
                  <Link
                    key={e.id}
                    to={e.to}
                    onClick={() => {
                      handleNavigation();
                      handleSelectedView(e.title);
                    }}
                    className={`navlink ${
                      view === e.title ? "border-b border-white" : "border-none"
                    } text-xl text-white max-md:text-xl font-semibold  transition-all duration-200 navlink tracking-[0] hover:opacity-50`}
                  >
                    {e.title}
                  </Link>
                );
              }
            })}
          </ul>
        </nav>
        <div className="relative flex items-center justify-center gap-8">
          <a
            href="#"
            target="_blank"
            className="fa-brands fa-facebook text-[wheat] text-2xl hover:opacity-50 transition-all duration-200 ease-in-out"
          ></a>
          <a
            href="#"
            target="_blank"
            className="fa-brands fa-linkedin text-[wheat] text-2xl hover:opacity-50 transition-all duration-200 ease-in-out"
          ></a>
          <a
            href="#"
            target="_blank"
            className="fa-brands fa-instagram text-[wheat] text-2xl hover:opacity-50 transition-all duration-200 ease-in-out"
          ></a>
          <div className="lg:hidden">
            <HiMenuAlt1
              size={20}
              className="text-white cursor-pointer"
              onClick={toggleMenu}
            />
          </div>
        </div>
      </div>

      <div
        ref={sidebarRef}
        className={`${
          isMenuOpen ? "translate-x-0" : "translate-x-full"
        } fixed top-0 right-0 w-full h-screen bg-[white] transition-transform duration-300 ease-in-out 
        lg:hidden z-200`}
      >
        <div className="flex justify-end p-4">
          <HiMenuAlt1
            size={20}
            className="text-black cursor-pointer"
            onClick={toggleMenu}
          />
        </div>
        <ul
          className={`flex flex-col justify-center items-center text-center h-full px-24 py-0 gap-12 text-black`}
        >
          {navlink.map((e) => {
            if (e.submenu) {
              return (
                <div key={e.id} className="w-full flex flex-col items-center">
                  <span
                    className="block text-xl font-normal cursor-pointer"
                    onClick={() =>
                      setIsMobileDropdownOpen(
                        isMobileDropdownOpen === e.id ? null : e.id
                      )
                    }
                  >
                    {e.title} &nbsp;
                    <i className="fa-solid fa-chevron-down text-sm relative bottom-[0.2rem]"></i>
                  </span>
                  <div
                    className={`w-full overflow-y-auto flex flex-col gap-2 justify-center items-center text-center transition-all duration-300 ease-in-out z-100
                    ${
                      isMobileDropdownOpen === e.id
                        ? "max-h-[300px] mt-4 -mb-8 translate-y-0 opacity-[1]"
                        : "max-h-0 -translate-y-full opacity-0"
                    }`}
                  >
                    {e.submenu.map((sub) => (
                      <Link
                        key={sub.id}
                        to={sub.to}
                        className="block text-lg text-black py-2 transition"
                        onClick={handleNavigation}
                      >
                        <i className="fa-solid fa-circle text-xs text-[grey]"></i>
                        &nbsp; {sub.title}
                      </Link>
                    ))}
                  </div>
                </div>
              );
            } else {
              return (
                <Link
                  key={e.id}
                  to={e.to}
                  onClick={handleNavigation}
                  className={`relative navlink text-xl text-black max-md:text-xl font-normal  transition-all duration-200 navlink tracking-[0] hover:opacity-50`}
                >
                  {e.title}
                </Link>
              );
            }
          })}
        </ul>
      </div>
    </>
  );
};

export default Header;
EOF

cat > src/globalComponents/Footer.jsx << 'EOF'
/* eslint-disable no-unused-vars */
import React from "react";

const Footer = () => {
  return (
    <>
      <div
        className={`px-8 py-3 bg-[crimson] w-full flex items-center justify-center text-center`}
      >
        <h2 className={`text-xl text-white font-semibold`}>
          ❤️ Made By Harshvardhan Sharma
        </h2>
      </div>
    </>
  );
};

export default Footer;
EOF

cat > src/features/auth/pages/Auth.jsx << 'EOF'
/* eslint-disable no-unused-vars */
import React from "react";
import AuthMain from "../components/AuthMain";

const Auth = () => {
  return (
    <>
      <div className={`relative w-full h-full`}>
        <AuthMain />
      </div>
    </>
  );
};

export default Auth;
EOF

cat > src/features/auth/components/AuthMain.jsx << 'EOF'
/* eslint-disable no-unused-vars */
import React, { useEffect, useRef, useState } from "react";
import { useDispatch, useSelector } from "react-redux";
import { motion } from "framer-motion";
import {
  setUserMode,
  setSelectRole,
  setCreateUsername,
  setPassword,
  setUsername,
  setCreateEmail,
  setCreatePassword,
} from "../services/toolkit/AuthSlice";
import { useNavigate } from "react-router-dom";
import ViewBtn from "../../../globalComponents/btns/ViewBtn";
import { FaCircleUser } from "react-icons/fa6";
import { handleLogin, handleSignup } from "../services/toolkit/AuthHandlers";
import { TbLoader2 } from "react-icons/tb";

const AuthMain = () => {
  const dispatch = useDispatch();
  const {
    userMode,
    selectRole,
    isLogin,
    isSignup,
    username,
    password,
    createUsername,
    createEmail,
    createPassword,
  } = useSelector((state) => state.authApp);
  const [showPassword, setShowPassword] = useState(false);
  const navigate = useNavigate();

  useEffect(() => {
    const savedMode = localStorage.getItem("authUserMode");
    if (savedMode) dispatch(setUserMode(savedMode));
  }, []);

  useEffect(() => {
    localStorage.setItem("authUserMode", userMode);
  }, [userMode]);

  return (
    <div className="relative w-screen h-screen overflow-hidden bg-[#93c4d0]">
      <div className="absolute inset-0 mt-0 flex items-center justify-center">
        {userMode === "login" ? (
          <motion.div
            initial={{ scale: 0.5, opacity: 0 }}
            animate={{ scale: 1, opacity: 1 }}
            transition={{ duration: 0.6, ease: "easeOut" }}
            className="backdrop-blur-sm bg-white rounded-3xl shadow-2xl 
            px-14 py-14 w-[35vw] flex flex-col gap-10"
          >
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.7, delay: 0.5 }}
              className="flex items-center justify-center gap-4"
            >
              <FaCircleUser
                size={50}
                className={`text-[#2957a2] shadow-xl rounded-full`}
              />
              <h2 className="font-semibold text-4xl text-[#111B69] italic">
                User Login
              </h2>
            </motion.div>
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.7, delay: 0.7 }}
              className="flex flex-col gap-6 w-full"
            >
              <label
                htmlFor="username"
                className="text-2xl font-bold text-[#37468a] tracking-wide flex items-center gap-[1.2rem]"
              >
                <div className="w-12 h-12 rounded-full bg-[#dfe6ff] flex items-center justify-center shadow-md">
                  <i className="fa-solid fa-user-tie text-[#37468a] text-2xl" />
                </div>
                Username
              </label>
              <input
                type="text"
                id="username"
                value={username}
                onChange={(e) => {
                  dispatch(setUsername(e.target.value));
                }}
                onKeyDown={(e) => {
                  if (e.key === "Enter" && !isLogin) {
                    dispatch(handleLogin({ username, password }));
                  }
                }}
                required
                autoComplete="off"
                placeholder="Enter your username"
                className={`w-full px-8 py-4 rounded-2xl bg-white/90 border-2 border-[#b5c4ff] text-xl font-semibold text-[#2b2b2b] focus:border-[#1b275b] focus:shadow-lg transition-all duration-300 outline-none ${
                  isLogin ? "cursor-not-allowed" : ""
                }`}
              />
            </motion.div>

            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.7, delay: 1.0 }}
              className="flex flex-col gap-6 w-full"
            >
              <label
                htmlFor="password"
                className="text-2xl font-bold text-[#37468a] tracking-wide flex items-center gap-[1.2rem]"
              >
                <div className="w-12 h-12 rounded-full bg-[#dfe6ff] flex items-center justify-center shadow-md">
                  <i className="fa-solid fa-key text-[#37468a] text-2xl" />
                </div>
                Password
              </label>
              <div className="relative w-full">
                <input
                  type={showPassword ? "text" : "password"}
                  id="password"
                  required
                  autoComplete="off"
                  value={password}
                  onChange={(e) => {
                    dispatch(setPassword(e.target.value));
                  }}
                  onKeyDown={(e) => {
                    if (e.key === "Enter" && !isLogin) {
                      dispatch(handleLogin({ username, password }));
                    }
                  }}
                  placeholder="Enter your password"
                  className={`w-full px-8 py-4 rounded-2xl bg-white/90 border-2 border-[#b5c4ff] text-xl font-semibold text-[#2b2b2b] focus:border-[#1b275b] focus:shadow-lg transition-all duration-300 outline-none ${
                    isLogin ? "cursor-not-allowed" : ""
                  }`}
                />
                <div
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute right-6 top-1/2 -translate-y-1/2 cursor-pointer text-xl text-[#37468a]"
                >
                  <i
                    className={`fa-solid ${
                      showPassword ? "fa-eye" : "fa-eye-slash"
                    }`}
                  ></i>
                </div>
              </div>
            </motion.div>

            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.7, delay: 1.3 }}
              className="w-full"
            >
              <ViewBtn
                btnTitle={
                  isLogin ? (
                    <div className="flex items-center justify-center">
                      <TbLoader2 size={30} className={`text-white`} />
                    </div>
                  ) : (
                    `Login`
                  )
                }
                btnFunc={() => dispatch(handleLogin({ username, password }))}
                disabled={isLogin}
                view={`full`}
                btnType={`Login`}
              />
            </motion.div>

            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.1, delay: 0.2 }}
              className={`flex items-center gap-2 justify-center`}
            >
              <h2 className={`text-xl text-[#212121] font-semibold`}>
                Not registered yet?
              </h2>
              <span
                onClick={
                  isLogin
                    ? undefined
                    : () => {
                        dispatch(setUserMode("signup"));
                      }
                }
                className={`text-[#543b7e] font-semibold text-xl underline cursor-pointer ${
                  isLogin ? "pointer-events-none opacity-60" : ""
                }`}
                tabIndex={isLogin ? -1 : 0}
                aria-disabled={isLogin}
              >
                Signup now
              </span>
            </motion.div>
          </motion.div>
        ) : userMode === "signup" ? (
          <motion.div
            initial={{ scale: 0.5, opacity: 0 }}
            animate={{ scale: 1, opacity: 1 }}
            transition={{ duration: 0.6, ease: "easeOut" }}
            className="backdrop-blur-sm bg-white rounded-3xl shadow-2xl px-14 
            py-14 w-[50vw] flex flex-col gap-10"
          >
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.7, delay: 0.5 }}
              className="flex items-center justify-center gap-4"
            >
              <FaCircleUser
                size={50}
                className={`text-[#2957a2] shadow-xl rounded-full`}
              />
              <h2 className="font-semibold text-4xl text-[#111B69] italic">
                User Signup
              </h2>
            </motion.div>

            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.7, delay: 0.7 }}
              className={`grid grid-cols-2 gap-8 justify-center`}
            >
              <motion.div
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.7, delay: 0.7 }}
                className="flex flex-col gap-6 w-full"
              >
                <label
                  htmlFor="createUsername"
                  className="text-2xl font-bold text-[#37468a] tracking-wide flex items-center gap-[1.2rem]"
                >
                  <div className="w-12 h-12 rounded-full bg-[#dfe6ff] flex items-center justify-center shadow-md">
                    <i className="fa-solid fa-user-tie text-[#37468a] text-2xl" />
                  </div>
                  Create Username
                </label>
                <input
                  type="text"
                  id="createUsername"
                  required
                  autoComplete="off"
                  value={createUsername}
                  onChange={(e) => {
                    dispatch(setCreateUsername(e.target.value));
                  }}
                  onKeyDown={(e) => {
                    if (e.key === "Enter" && !isSignup) {
                      dispatch(
                        handleSignup({
                          createUsername,
                          createEmail,
                          createPassword,
                        })
                      );
                    }
                  }}
                  placeholder="Set your username"
                  className={`w-full px-8 py-4 rounded-2xl bg-white/90 border-2 border-[#b5c4ff] text-xl font-semibold text-[#2b2b2b] focus:border-[#1b275b] focus:shadow-lg transition-all duration-300 outline-none ${
                    isSignup ? "cursor-not-allowed" : ""
                  }`}
                />
              </motion.div>
              <motion.div
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.7, delay: 1.0 }}
                className="flex flex-col gap-6 w-full"
              >
                <label
                  htmlFor="email"
                  className="text-2xl font-bold text-[#37468a] tracking-wide flex items-center gap-[1.2rem]"
                >
                  <div className="w-12 h-12 rounded-full bg-[#dfe6ff] flex items-center justify-center shadow-md">
                    <i className="fa-solid fa-envelope text-[#37468a] text-2xl" />
                  </div>
                  Email
                </label>
                <input
                  type="text"
                  id="email"
                  required
                  value={createEmail}
                  onChange={(e) => {
                    dispatch(setCreateEmail(e.target.value));
                  }}
                  onKeyDown={(e) => {
                    if (e.key === "Enter" && !isSignup) {
                      dispatch(
                        handleSignup({
                          createUsername,
                          createEmail,
                          createPassword,
                        })
                      );
                    }
                  }}
                  autoComplete="off"
                  placeholder="Set your email"
                  className={`w-full px-8 py-4 rounded-2xl bg-white/90 border-2 border-[#b5c4ff] text-xl font-semibold text-[#2b2b2b] focus:border-[#1b275b] focus:shadow-lg transition-all duration-300 outline-none ${
                    isSignup ? "cursor-not-allowed" : ""
                  }`}
                />
              </motion.div>
            </motion.div>
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.7, delay: 1.0 }}
              className={`grid grid-cols-2 gap-8 justify-center`}
            >
              <motion.div
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.7, delay: 1.3 }}
                className="flex flex-col gap-6 w-full"
              >
                <label
                  htmlFor="password"
                  className="text-2xl font-bold text-[#37468a] tracking-wide flex items-center gap-[1.2rem]"
                >
                  <div className="w-12 h-12 rounded-full bg-[#dfe6ff] flex items-center justify-center shadow-md">
                    <i className="fa-solid fa-key text-[#37468a] text-2xl" />
                  </div>
                  Create Password
                </label>
                <div className="relative w-full">
                  <input
                    type={showPassword ? "text" : "password"}
                    id="password"
                    required
                    value={createPassword}
                    onChange={(e) => {
                      dispatch(setCreatePassword(e.target.value));
                    }}
                    onKeyDown={(e) => {
                      if (e.key === "Enter" && !isSignup) {
                        dispatch(
                          handleSignup({
                            createUsername,
                            createEmail,
                            createPassword,
                          })
                        );
                      }
                    }}
                    autoComplete="off"
                    placeholder="Set your password"
                    className={`w-full px-8 py-4 rounded-2xl bg-white/90 border-2 border-[#b5c4ff] text-xl font-semibold text-[#2b2b2b] focus:border-[#1b275b] focus:shadow-lg transition-all duration-300 outline-none ${
                      isSignup ? "cursor-not-allowed" : ""
                    }`}
                  />
                  <div
                    onClick={() => setShowPassword(!showPassword)}
                    className="absolute right-6 top-1/2 -translate-y-1/2 cursor-pointer text-xl text-[#37468a]"
                  >
                    <i
                      className={`fa-solid ${
                        showPassword ? "fa-eye" : "fa-eye-slash"
                      }`}
                    ></i>
                  </div>
                </div>
              </motion.div>
              <motion.div
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.7, delay: 1.5 }}
                className="flex flex-col gap-6 w-full"
              >
                <label
                  htmlFor="signup-password"
                  className="text-2xl font-bold text-[#37468a] tracking-wide flex items-center gap-[1.2rem]"
                >
                  <div className="w-12 h-12 rounded-full bg-[#dfe6ff] flex items-center justify-center shadow-md">
                    <i className="fa-solid fa-key text-[#37468a] text-2xl" />
                  </div>
                  Role
                </label>
                <div className="relative w-full">
                  <select
                    id="userRole"
                    value={selectRole}
                    required
                    onChange={(e) => dispatch(setSelectRole(e.target.value))}
                    className={`w-full px-8 py-4 rounded-2xl bg-white/90 border-2 border-[#b5c4ff] text-xl font-semibold text-[#2b2b2b] focus:border-[#1b275b] focus:shadow-lg transition-all duration-300 outline-none cursor-pointer ${
                      isSignup ? "cursor-not-allowed" : ""
                    }`}
                  >
                    {["admin", "user"].map((role, index) => (
                      <option key={index}>{role.toLocaleLowerCase()}</option>
                    ))}
                  </select>
                </div>
              </motion.div>
            </motion.div>
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.7, delay: 1.7 }}
              className="w-full mt-0"
            >
              <ViewBtn
                btnTitle={
                  isSignup ? (
                    <div className="flex items-center justify-center">
                      <TbLoader2 size={30} className={`text-white`} />
                    </div>
                  ) : (
                    `Signup`
                  )
                }
                btnFunc={() =>
                  dispatch(
                    handleSignup({
                      createUsername,
                      createEmail,
                      createPassword,
                    })
                  )
                }
                disabled={isSignup}
                view={`full`}
                btnType={`Signup`}
              />
            </motion.div>

            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.1, delay: 0.2 }}
              className="flex items-center gap-2 justify-center"
            >
              <h2 className="text-xl text-[#212121] font-semibold">
                Already have account?
              </h2>
              <span
                onClick={() => {
                  dispatch(setUserMode("login"));
                }}
                className="text-[#212121] font-semibold text-xl cursor-pointer"
              >
                Back to
              </span>
              <span
                onClick={
                  isSignup
                    ? undefined
                    : () => {
                        dispatch(setUserMode("login"));
                      }
                }
                className={`text-[#543b7e] font-semibold text-xl underline cursor-pointer ${
                  isSignup ? "pointer-events-none opacity-60" : ""
                }`}
                tabIndex={isSignup ? -1 : 0}
                aria-disabled={isSignup}
              >
                Login
              </span>
            </motion.div>
          </motion.div>
        ) : null}
      </div>
    </div>
  );
};

export default AuthMain;
EOF

cat > src/globalService/Data.js << 'EOF'
export const NavLink = [
  {
    id: 1,
    title: "Home",
    to: "/default",
  },
  {
    id: 2,
    title: "About Us",
    to: "/default",
  },
  {
    id: 3,
    title: "Course",
    to: "#",
    submenu: [
      { id: 1, title: "Our Course", to: "/default" },
      {
        id: 2,
        title: "AI Course",
        to: "/default",
      },
    ],
  },
  {
    id: 7,
    title: "Contact Us",
    to: "/default",
  },
];
EOF

cat > index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <link rel="icon" type="image/svg+xml" href="/logo.svg" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>HVS App</title>
    <link rel="preconnect" href="https://fonts.googleapis.com" />
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@100..900&family=Lato:wght@100;300;400;700;900&family=Raleway:wght@100..900&family=Roboto+Serif:wght@100..900&family=Roboto:wght@100;300;400;500;700;900&family=Saira:wght@100..900&display=swap" rel="stylesheet" />
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.jsx"></script>
    <script src="https://kit.fontawesome.com/c855874020.js" crossorigin="anonymous"></script>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    <script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
  </body>
</html>
EOF
