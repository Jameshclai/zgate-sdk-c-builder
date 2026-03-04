#!/usr/bin/env python3
"""
自動修正 tlsuv src/openssl/keys.c 的 C89 相容：
privkey_store_cert 內變數需在函數開頭宣告，否則 MinGW 等編譯器會報 'subj_name' undeclared。
用法: python3 fix-tlsuv-keys-c89.py path/to/keys.c
"""
import re
import sys

DECL_BLOCK = r"""    X509_STORE *store;
    STACK_OF(X509_OBJECT) *objects;
    X509_OBJECT *obj;
    X509 *c;
    unsigned char *subj_der = NULL;
    int subjlen;
    char *der = NULL;
    int derlen;
    int rc;

"""

# 中段宣告區塊（\s* 容許多種空白/換行）→ 改為僅賦值
BAD_MIDDLE = re.compile(
    r"\s*X509_STORE\s+\*store\s*=\s*\(\(struct cert_s\*\)cert\)->cert;\s*\n"
    r"\s*STACK_OF\(X509_OBJECT\)\s+\*objects\s*=\s*X509_STORE_get0_objects\(store\);\s*\n"
    r"\s*X509_OBJECT\s+\*obj\s*=\s*sk_X509_OBJECT_value\(objects,\s*0\);\s*\n"
    r"\s*X509\s+\*c\s*=\s*X509_OBJECT_get0_X509\(obj\);\s*\n"
    r"\s*X509_NAME\s+\*subj_name\s*=\s*X509_get_subject_name\(c\);\s*\n"
    r"\s*unsigned char\s+\*subj_der\s*=\s*NULL;\s*\n"
    r"\s*int subjlen\s*=\s*i2d_X509_NAME\(subj_name,\s*&subj_der\);\s*\n"
    r"\s*char\s+\*der\s*=\s*NULL;\s*\n"
    r"\s*int derlen\s*=\s*i2d_X509\(c,\s*\(unsigned char\s+\*\*\)\s*&der\);\s*\n"
    r"\s*int rc\s*=\s*p11_store_key_cert\(p11_key,\s*der,\s*derlen,\s*\(char\*\)subj_der,\s*subjlen\);\s*",
    re.MULTILINE,
)

GOOD_MIDDLE = """    store = ((struct cert_s*)cert)->cert;
    objects = X509_STORE_get0_objects(store);
    obj = sk_X509_OBJECT_value(objects, 0);
    c = X509_OBJECT_get0_X509(obj);
    subjlen = i2d_X509_NAME(X509_get_subject_name(c), &subj_der);
    derlen = i2d_X509(c, (unsigned char **) &der);
    rc = p11_store_key_cert(p11_key, der, derlen, (char*)subj_der, subjlen);
"""

def need_fix(content):
    return "X509_NAME *subj_name = X509_get_subject_name(c)" in content


def already_fixed(content):
    return "subjlen = i2d_X509_NAME(X509_get_subject_name(c)," in content


def apply_fix(content):
    if already_fixed(content):
        return content, False
    if not need_fix(content):
        return content, False
    match = BAD_MIDDLE.search(content)
    if not match:
        return content, False
    # 只在 privkey_store_cert 內插入宣告（該函數內、且在此中段區塊之前的那行 p11_key_ctx）
    start = match.start()
    idx_func = content.rfind("static int privkey_store_cert", 0, start)
    if idx_func == -1:
        return content, False
    idx_p11 = content.find("p11_key_ctx *p11_key = NULL;", idx_func, start)
    if idx_p11 == -1 or idx_p11 >= start:
        return content, False
    insert_pos = content.find("\n", idx_p11) + 1
    out = content[:insert_pos] + DECL_BLOCK + content[insert_pos:]
    out = BAD_MIDDLE.sub(GOOD_MIDDLE, out, count=1)
    return out, True


def main():
    path = sys.argv[1] if len(sys.argv) > 1 else None
    if not path:
        print("Usage: fix-tlsuv-keys-c89.py <keys.c>", file=sys.stderr)
        sys.exit(2)
    with open(path, "r", encoding="utf-8", errors="replace") as f:
        content = f.read()
    out, changed = apply_fix(content)
    if changed:
        with open(path, "w", encoding="utf-8", newline="\n") as f:
            f.write(out)
        print(f"Applied C89 fix: {path}", file=sys.stderr)
    sys.exit(0)


if __name__ == "__main__":
    main()
