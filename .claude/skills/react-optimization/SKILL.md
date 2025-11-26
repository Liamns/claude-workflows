---
name: react-optimization
description: React 렌더링 최적화, useMemo/useCallback 적용, 불필요한 리렌더링 방지 패턴을 제공합니다. implementer-unified와 reviewer-unified에서 활용됩니다.
allowed-tools: Read, Grep, Glob
---

# React Optimization Skill

React 애플리케이션의 렌더링 성능을 최적화하는 패턴과 가이드를 제공합니다.

## 사용 시점

다음과 같은 상황에서 활성화됩니다:

- 컴포넌트 리렌더링 최적화 요청
- 성능 이슈 분석 및 개선
- useMemo/useCallback 적용 필요 시
- React.memo 적용 판단 시
- 코드 리뷰에서 성능 관련 검토

## 핵심 최적화 패턴

### 1. React.memo 적용 기준

**적용해야 하는 경우:**
```typescript
// ✅ Props가 자주 변경되지 않는 컴포넌트
const ExpensiveList = React.memo(function ExpensiveList({ items }: Props) {
  return (
    <ul>
      {items.map(item => (
        <li key={item.id}>{item.name}</li>
      ))}
    </ul>
  );
});

// ✅ 부모가 자주 리렌더링되지만 자식 props는 안정적인 경우
const ChildComponent = React.memo(function ChildComponent({ onClick }: Props) {
  return <button onClick={onClick}>Click</button>;
});
```

**적용하지 않아야 하는 경우:**
```typescript
// ❌ Props가 매번 새로운 객체/배열인 경우 (memo 무효화)
// ❌ 컴포넌트가 항상 다른 props를 받는 경우
// ❌ 렌더링 비용이 낮은 단순 컴포넌트
// ❌ children을 받는 컴포넌트 (대부분 비효율적)
```

### 2. useMemo 적용 패턴

**적용해야 하는 경우:**
```typescript
// ✅ 비용이 큰 계산
const sortedItems = useMemo(() => {
  return items.slice().sort((a, b) => a.price - b.price);
}, [items]);

// ✅ 참조 동등성이 중요한 객체
const filterConfig = useMemo(() => ({
  status: selectedStatus,
  category: selectedCategory,
}), [selectedStatus, selectedCategory]);

// ✅ 복잡한 데이터 변환
const processedData = useMemo(() => {
  return data.map(item => ({
    ...item,
    formattedDate: formatDate(item.date),
    calculatedValue: expensiveCalculation(item),
  }));
}, [data]);
```

**적용하지 않아야 하는 경우:**
```typescript
// ❌ 단순 값 (오버헤드가 더 큼)
const doubled = useMemo(() => value * 2, [value]); // 불필요

// ❌ 매번 달라지는 의존성
const result = useMemo(() => compute(a, b), [a, b, c, d, e]); // 캐시 무효화 빈번
```

### 3. useCallback 적용 패턴

**적용해야 하는 경우:**
```typescript
// ✅ memo된 자식 컴포넌트에 전달하는 콜백
const handleClick = useCallback(() => {
  onItemSelect(item.id);
}, [item.id, onItemSelect]);

// ✅ useEffect 의존성으로 사용되는 함수
const fetchData = useCallback(async () => {
  const result = await api.getData(id);
  setData(result);
}, [id]);

useEffect(() => {
  fetchData();
}, [fetchData]);

// ✅ 커스텀 훅에서 반환하는 함수
function useCounter() {
  const [count, setCount] = useState(0);

  const increment = useCallback(() => {
    setCount(c => c + 1);
  }, []);

  return { count, increment };
}
```

**적용하지 않아야 하는 경우:**
```typescript
// ❌ memo되지 않은 컴포넌트에 전달
// ❌ 인라인으로 사용되는 간단한 핸들러
// ❌ JSX에서 직접 사용되는 이벤트 핸들러 (memo 없이)
```

### 4. 리렌더링 방지 패턴

**상태 분리:**
```typescript
// ❌ 하나의 큰 상태
const [state, setState] = useState({ user, items, filters });

// ✅ 분리된 상태
const [user, setUser] = useState(initialUser);
const [items, setItems] = useState([]);
const [filters, setFilters] = useState(defaultFilters);
```

**Context 최적화:**
```typescript
// ❌ 모든 값이 한 Context에
const AppContext = createContext({ user, theme, settings, ... });

// ✅ 분리된 Context
const UserContext = createContext(user);
const ThemeContext = createContext(theme);
const SettingsContext = createContext(settings);

// ✅ 값과 디스패치 분리
const StateContext = createContext(state);
const DispatchContext = createContext(dispatch);
```

**이벤트 핸들러 최적화:**
```typescript
// ❌ 매번 새로운 함수
<button onClick={() => handleClick(item.id)}>

// ✅ data 속성 활용
const handleClick = useCallback((e: React.MouseEvent<HTMLButtonElement>) => {
  const id = e.currentTarget.dataset.id;
  onSelect(id);
}, [onSelect]);

<button data-id={item.id} onClick={handleClick}>
```

### 5. 리스트 렌더링 최적화

```typescript
// ✅ 안정적인 key 사용
{items.map(item => (
  <ListItem key={item.id} item={item} />
))}

// ✅ 가상화 적용 (대용량 리스트)
import { FixedSizeList } from 'react-window';

<FixedSizeList
  height={400}
  itemCount={items.length}
  itemSize={50}
  width="100%"
>
  {({ index, style }) => (
    <div style={style}>
      <ListItem item={items[index]} />
    </div>
  )}
</FixedSizeList>
```

## 성능 분석 체크리스트

### 리렌더링 감지
```typescript
// 개발 중 리렌더링 확인용
function useWhyDidYouUpdate(name: string, props: Record<string, any>) {
  const previousProps = useRef(props);

  useEffect(() => {
    if (previousProps.current) {
      const allKeys = Object.keys({ ...previousProps.current, ...props });
      const changedProps: Record<string, any> = {};

      allKeys.forEach(key => {
        if (previousProps.current[key] !== props[key]) {
          changedProps[key] = {
            from: previousProps.current[key],
            to: props[key],
          };
        }
      });

      if (Object.keys(changedProps).length) {
        console.log('[why-did-you-update]', name, changedProps);
      }
    }

    previousProps.current = props;
  });
}
```

### 검토 항목
- [ ] 불필요한 리렌더링이 발생하는 컴포넌트 식별
- [ ] React.memo 적용 대상 선정
- [ ] useMemo/useCallback 필요성 검토
- [ ] Context 구조 최적화 필요성 확인
- [ ] 대용량 리스트 가상화 필요성 확인

## 연동 Agent/Skill

- **implementer-unified**: 구현 시 패턴 적용
- **reviewer-unified**: 코드 리뷰 시 성능 검토
- **bug-fix-pattern**: 성능 관련 버그 수정

## 사용 예시

```
사용자: "이 컴포넌트가 너무 자주 리렌더링됩니다"

1. 컴포넌트 코드 분석
2. 리렌더링 원인 파악
3. react-optimization 패턴 적용
4. 최적화 코드 제안
5. 검증 방법 안내
```
