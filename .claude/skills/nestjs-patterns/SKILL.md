---
name: nestjs-patterns
description: NestJS 모듈 구조, 의존성 주입, 데코레이터 패턴을 제공합니다. 백엔드 API 구현 시 아키텍처 일관성을 유지합니다. implementer-unified와 api-designer에서 활용됩니다.
allowed-tools: Read, Grep, Glob
---

# NestJS Patterns Skill

NestJS 애플리케이션의 아키텍처 패턴과 모범 사례를 제공합니다.

## 사용 시점

다음과 같은 상황에서 활성화됩니다:

- NestJS 모듈/컨트롤러/서비스 생성
- API 엔드포인트 구현
- 의존성 주입 설계
- 미들웨어/가드/인터셉터 구현
- 데이터베이스 연동 (TypeORM/Prisma)

## 핵심 아키텍처 패턴

### 1. 모듈 구조

**표준 모듈 구조:**
```
src/
├── modules/
│   └── users/
│       ├── users.module.ts
│       ├── users.controller.ts
│       ├── users.service.ts
│       ├── dto/
│       │   ├── create-user.dto.ts
│       │   └── update-user.dto.ts
│       ├── entities/
│       │   └── user.entity.ts
│       └── interfaces/
│           └── user.interface.ts
├── common/
│   ├── decorators/
│   ├── filters/
│   ├── guards/
│   ├── interceptors/
│   └── pipes/
└── config/
```

### 2. 컨트롤러 패턴

```typescript
// users.controller.ts
import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Body,
  Param,
  Query,
  UseGuards,
  HttpStatus,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { UsersService } from './users.service';
import { CreateUserDto } from './dto/create-user.dto';
import { UpdateUserDto } from './dto/update-user.dto';
import { JwtAuthGuard } from '@/common/guards/jwt-auth.guard';

@ApiTags('users')
@Controller('users')
@UseGuards(JwtAuthGuard)
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Post()
  @ApiOperation({ summary: '사용자 생성' })
  @ApiResponse({ status: HttpStatus.CREATED, description: '사용자 생성 성공' })
  @ApiResponse({ status: HttpStatus.BAD_REQUEST, description: '잘못된 요청' })
  async create(@Body() createUserDto: CreateUserDto) {
    return this.usersService.create(createUserDto);
  }

  @Get()
  @ApiOperation({ summary: '사용자 목록 조회' })
  async findAll(@Query('page') page: number = 1) {
    return this.usersService.findAll(page);
  }

  @Get(':id')
  @ApiOperation({ summary: '사용자 상세 조회' })
  async findOne(@Param('id') id: string) {
    return this.usersService.findOne(id);
  }

  @Put(':id')
  @ApiOperation({ summary: '사용자 수정' })
  async update(@Param('id') id: string, @Body() updateUserDto: UpdateUserDto) {
    return this.usersService.update(id, updateUserDto);
  }

  @Delete(':id')
  @ApiOperation({ summary: '사용자 삭제' })
  async remove(@Param('id') id: string) {
    return this.usersService.remove(id);
  }
}
```

### 3. 서비스 패턴

```typescript
// users.service.ts
import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from './entities/user.entity';
import { CreateUserDto } from './dto/create-user.dto';
import { UpdateUserDto } from './dto/update-user.dto';

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
  ) {}

  async create(createUserDto: CreateUserDto): Promise<User> {
    const user = this.userRepository.create(createUserDto);
    return this.userRepository.save(user);
  }

  async findAll(page: number = 1, limit: number = 10): Promise<User[]> {
    return this.userRepository.find({
      skip: (page - 1) * limit,
      take: limit,
    });
  }

  async findOne(id: string): Promise<User> {
    const user = await this.userRepository.findOne({ where: { id } });
    if (!user) {
      throw new NotFoundException(`User #${id} not found`);
    }
    return user;
  }

  async update(id: string, updateUserDto: UpdateUserDto): Promise<User> {
    const user = await this.findOne(id);
    Object.assign(user, updateUserDto);
    return this.userRepository.save(user);
  }

  async remove(id: string): Promise<void> {
    const user = await this.findOne(id);
    await this.userRepository.remove(user);
  }
}
```

### 4. DTO 패턴

```typescript
// dto/create-user.dto.ts
import { IsString, IsEmail, MinLength, IsOptional } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class CreateUserDto {
  @ApiProperty({ description: '사용자 이메일', example: 'user@example.com' })
  @IsEmail({}, { message: '올바른 이메일 형식이 아닙니다' })
  email: string;

  @ApiProperty({ description: '비밀번호', minLength: 8 })
  @IsString()
  @MinLength(8, { message: '비밀번호는 최소 8자 이상이어야 합니다' })
  password: string;

  @ApiPropertyOptional({ description: '이름' })
  @IsString()
  @IsOptional()
  name?: string;
}

// dto/update-user.dto.ts
import { PartialType } from '@nestjs/swagger';
import { CreateUserDto } from './create-user.dto';

export class UpdateUserDto extends PartialType(CreateUserDto) {}
```

### 5. Entity 패턴

```typescript
// entities/user.entity.ts
import {
  Entity,
  Column,
  PrimaryGeneratedColumn,
  CreateDateColumn,
  UpdateDateColumn,
} from 'typeorm';

@Entity('users')
export class User {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ unique: true })
  email: string;

  @Column()
  password: string;

  @Column({ nullable: true })
  name: string;

  @Column({ default: true })
  isActive: boolean;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
```

### 6. Guard 패턴

```typescript
// common/guards/jwt-auth.guard.ts
import { Injectable, ExecutionContext } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { Reflector } from '@nestjs/core';
import { IS_PUBLIC_KEY } from '../decorators/public.decorator';

@Injectable()
export class JwtAuthGuard extends AuthGuard('jwt') {
  constructor(private reflector: Reflector) {
    super();
  }

  canActivate(context: ExecutionContext) {
    const isPublic = this.reflector.getAllAndOverride<boolean>(IS_PUBLIC_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);

    if (isPublic) {
      return true;
    }

    return super.canActivate(context);
  }
}
```

### 7. 커스텀 데코레이터

```typescript
// common/decorators/current-user.decorator.ts
import { createParamDecorator, ExecutionContext } from '@nestjs/common';

export const CurrentUser = createParamDecorator(
  (data: string, ctx: ExecutionContext) => {
    const request = ctx.switchToHttp().getRequest();
    const user = request.user;
    return data ? user?.[data] : user;
  },
);

// 사용 예시
@Get('profile')
getProfile(@CurrentUser() user: User) {
  return user;
}

@Get('profile/email')
getEmail(@CurrentUser('email') email: string) {
  return { email };
}
```

### 8. Exception Filter

```typescript
// common/filters/http-exception.filter.ts
import {
  ExceptionFilter,
  Catch,
  ArgumentsHost,
  HttpException,
  HttpStatus,
} from '@nestjs/common';
import { Response } from 'express';

@Catch()
export class AllExceptionsFilter implements ExceptionFilter {
  catch(exception: unknown, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();

    const status =
      exception instanceof HttpException
        ? exception.getStatus()
        : HttpStatus.INTERNAL_SERVER_ERROR;

    const message =
      exception instanceof HttpException
        ? exception.getResponse()
        : '서버 내부 오류가 발생했습니다';

    response.status(status).json({
      statusCode: status,
      message: typeof message === 'string' ? message : (message as any).message,
      timestamp: new Date().toISOString(),
    });
  }
}
```

### 9. Interceptor 패턴

```typescript
// common/interceptors/transform.interceptor.ts
import {
  Injectable,
  NestInterceptor,
  ExecutionContext,
  CallHandler,
} from '@nestjs/common';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';

export interface Response<T> {
  data: T;
  statusCode: number;
  timestamp: string;
}

@Injectable()
export class TransformInterceptor<T>
  implements NestInterceptor<T, Response<T>>
{
  intercept(
    context: ExecutionContext,
    next: CallHandler,
  ): Observable<Response<T>> {
    return next.handle().pipe(
      map((data) => ({
        data,
        statusCode: context.switchToHttp().getResponse().statusCode,
        timestamp: new Date().toISOString(),
      })),
    );
  }
}
```

## 검토 체크리스트

- [ ] 모듈 구조가 표준을 따르는가
- [ ] DTO에 검증 데코레이터가 적용되었는가
- [ ] Swagger 문서화가 완료되었는가
- [ ] 적절한 에러 처리가 구현되었는가
- [ ] Guard/Interceptor가 적절히 적용되었는가

## 연동 Agent/Skill

- **api-designer**: API 설계 시 패턴 참조
- **implementer-unified**: 백엔드 구현
- **architect-unified**: 아키텍처 검증

## 사용 예시

```
사용자: "사용자 관리 API를 만들어줘"

1. nestjs-patterns 참조
2. 모듈 구조 생성
3. Controller/Service/DTO/Entity 구현
4. Swagger 문서화
5. 검증 로직 적용
```
