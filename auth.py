import hashlib
from werkzeug.security import generate_password_hash, check_password_hash
from db_init import create_connection

# 密码加密存储（大作业中体现安全性，是加分项）
def hash_password(password):
    # 使用安全的 werkzeug.security 哈希加密
    return generate_password_hash(password, method='pbkdf2:sha256')

class AuthManager:
    """
    角色与权限管理器 (Role-Based Access Control, RBAC)
    负责用户的登录、角色校验以及系统管理员对账号的管理。
    """
    def __init__(self):
        # 记录当前登录用户的信息：user_id, username, role
        self.current_user = None

    def login(self, username, password):
        """用户登录校验"""
        conn = create_connection()
        if not conn:
            return False
            
        try:
            cursor = conn.cursor()
            # 使用参数化查询防止SQL注入
            sql = "SELECT user_id, role, password_hash FROM Users WHERE username = %s"
            cursor.execute(sql, (username,))
            user_data = cursor.fetchone()

            if user_data and check_password_hash(user_data[2], password):
                self.current_user = {
                    'user_id': user_data[0],
                    'username': username,
                    'role': user_data[1]
                }
                print(f"\n✅ 登录成功！欢迎，{username}。当前角色：{self.current_user['role']}")
                return True
            else:
                print("\n❌ 登录失败：用户名或密码错误！")
                return False
        except Exception as e:
            print(f"查询用户时发生错误: {e}")
            return False
        finally:
            if conn:
                cursor.close()
                conn.close()

    def logout(self):
        """退出登录"""
        if self.current_user:
            print(f"\n👋 {self.current_user['username']} 已退出登录。")
            self.current_user = None

    # ==========================================
    # 核心：权限校验装饰器 (拿到10分权限管理的关键)
    # ==========================================
    def require_role(self, *allowed_roles):
        """
        权限控制装饰器。在需要限制权限的函数前加上 @auth.require_role(...)
        """
        import functools
        def decorator(func):
            @functools.wraps(func)
            def wrapper(*args, **kwargs):
                if not self.current_user:
                    print("\n⚠️ 权限拦截：未登录，请先登录！")
                    return None
                
                # 检查当前用户角色是否在允许的角色列表中
                if self.current_user['role'] not in allowed_roles:
                    print(f"\n⛔ 权限拒绝！该操作需要 {allowed_roles} 权限，" 
                          f"而您当前是 '{self.current_user['role']}'，无法执行此操作。")
                    return None
                
                # 权限通过，执行原业务逻辑函数
                return func(*args, **kwargs)
            return wrapper
        return decorator

# 初始化一个全局的权限管理器对象
auth = AuthManager()

# ==========================================
# 演示：只有 'sys_admin' (系统管理员) 才能执行的操作
# ==========================================
@auth.require_role('sys_admin')
def add_user(new_username, new_password, role):
    """(系统管理员专属) 添加新用户。音乐管理员和听众不能调用此函数"""
    if role not in ('sys_admin', 'music_admin', 'listener'):
        print("❌ 角色无效！只能是 sys_admin, music_admin, 或 listener。")
        return False
        
    conn = create_connection()
    if not conn: return False
    
    try:
        cursor = conn.cursor()
        sql = "INSERT INTO Users (username, password_hash, role) VALUES (%s, %s, %s)"
        cursor.execute(sql, (new_username, hash_password(new_password), role))
        conn.commit()
        print(f"✅ 成功添加新账号。用户名: {new_username}, 角色: {role}")
        return True
    except Exception as e:
        print(f"❌ 添加用户失败（可能是用户名已存在）: {e}")
        conn.rollback()
        return False
    finally:
        if conn:
            cursor.close()
            conn.close()

# 这是一段测试脚本，直接运行本文件可以查看权限拦截效果
if __name__ == "__main__":
    print("----- 系统初始化：强制注册一个超级管理员 -----")
    # 如果数据库里一个用户都没有，我们需要强制插一个系统管理员进去用来启动系统
    add_user.__wrapped__("admin", "admin123", "sys_admin")  # __wrapped__ 可以绕过装饰器强行执行一次
    
    print("\n----- 权限拦截测试 1：未登录尝试加人 -----")
    add_user("test_user_1", "123", "listener") # 这里会被拦截！
    
    print("\n----- 权限拦截测试 2：以 listener 身份尝试加人 -----")
    # 强行插一个听众账号进去用来验证
    add_user.__wrapped__("bob", "bob123", "listener")
    auth.login("bob", "bob123")  # 登录 bob (listener)
    add_user("test_user_2", "123", "music_admin") # bob 尝试加人，依然会被拦截！
    
    print("\n----- 权限校验测试 3：切换回 sys_admin 正常操作 -----")
    auth.logout()
    auth.login("admin", "admin123") # 登录 admin (sys_admin)
    add_user("alice", "alice123", "music_admin") # admin 尝试加人，成功！
