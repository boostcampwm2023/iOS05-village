import {
  Body,
  Controller,
  HttpException,
  Post,
  UseGuards,
} from '@nestjs/common';
import { LoginService, SocialProperties } from './login.service';
import { AppleLoginDto } from './appleLoginDto';
import { AuthGuard } from 'src/utils/auth.guard';

@Controller('login')
@UseGuards(AuthGuard)
export class LoginController {
  constructor(private readonly loginService: LoginService) {}

  @Post('appleOAuth') // 임시
  async signInWithApple(@Body() body: AppleLoginDto) {
    const socialProperties: SocialProperties =
      await this.loginService.appleOAuth(body);
    if (!socialProperties) {
      throw new HttpException('토큰이 유효하지 않음', 401);
    }
    return await this.loginService.login(socialProperties);
  }
}
