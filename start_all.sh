#!/bin/bash
set -e

# Khởi động hệ thống VinUni Legal AI Multi-Agent
# Registry phải chạy trước, rồi leaf agents, rồi orchestrators

if [ -z "$PYTHON" ]; then
    if [ -x ".venv/bin/python" ]; then
        PYTHON=".venv/bin/python"
    else
        PYTHON="python"
    fi
fi

echo "Python: $("$PYTHON" --version)"
echo ""

echo "Khởi động Registry trên port 10000..."
"$PYTHON" -m registry &
REGISTRY_PID=$!
sleep 2

echo "Khởi động Tax Agent trên port 10102..."
"$PYTHON" -m tax_agent &
TAX_PID=$!

echo "Khởi động Compliance Agent trên port 10103..."
"$PYTHON" -m compliance_agent &
COMPLIANCE_PID=$!
sleep 3

echo "Khởi động Law Agent trên port 10101..."
"$PYTHON" -m law_agent &
LAW_PID=$!
sleep 3

echo "Khởi động Customer Agent trên port 10100..."
"$PYTHON" -m customer_agent &
CUSTOMER_PID=$!

echo ""
echo "Tất cả services đã khởi động:"
echo "  Registry:         http://localhost:10000"
echo "  Customer Agent:   http://localhost:10100"
echo "  Law Agent:        http://localhost:10101"
echo "  Tax Agent:        http://localhost:10102"
echo "  Compliance Agent: http://localhost:10103"
echo ""
echo "Chạy test_client.py để gửi câu hỏi:"
echo "  $PYTHON test_client.py"
echo ""
echo "Nhấn Ctrl+C để dừng tất cả services."

# Chờ tất cả background processes
wait $REGISTRY_PID $TAX_PID $COMPLIANCE_PID $LAW_PID $CUSTOMER_PID
