# 비동기 처리 패턴

## 1. Unmount 후 setState

### 문제
```typescript
const handleSubmit = async () => {
  await submitForm();
  setIsSubmitting(false); // Warning: Can't perform a React state update on an unmounted component
};
```

### 해결책
```typescript
// ✅ try-finally 사용
const handleSubmit = async () => {
  try {
    await submitForm();
  } catch (error) {
    console.error(error);
  } finally {
    setIsSubmitting(false);
  }
};

// ✅ Cleanup 함수 사용
useEffect(() => {
  let isMounted = true;

  async function fetchData() {
    const data = await fetchUser();
    if (isMounted) {
      setUser(data);
    }
  }

  fetchData();

  return () => {
    isMounted = false;
  };
}, []);
```

## 2. Promise 에러 처리 누락

### 문제
```typescript
// ❌ Unhandled promise rejection
const handleClick = async () => {
  await riskyOperation();
};
```

### 해결책
```typescript
// ✅ try-catch
const handleClick = async () => {
  try {
    await riskyOperation();
  } catch (error) {
    console.error('Operation failed:', error);
    // 에러 UI 표시
  }
};
```
