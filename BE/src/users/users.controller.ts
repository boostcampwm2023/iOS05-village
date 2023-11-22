import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Param,
  Delete,
  UseInterceptors,
  UploadedFiles,
  ValidationPipe,
  HttpException,
  UploadedFile,
  HttpCode,
} from '@nestjs/common';
import { UsersService } from './users.service';
import { CreateUserDto } from './createUser.dto';
import { FileInterceptor } from '@nestjs/platform-express';
import { MultiPartBody } from 'src/utils/multiPartBody.decorator';
import { UpdateUsersDto } from './usersUpdate.dto';

@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get(':id')
  async usersDetails(@Param('id') userId) {
    const user = await this.usersService.findUserById(userId);
    if (user === null) {
      throw new HttpException('유저가 존재하지않습니다.', 404);
    } else {
      return user;
    }
  }

  @Post()
  @UseInterceptors(FileInterceptor('profileImage'))
  async usersCreate(
    @UploadedFiles() files: Express.Multer.File,
    @MultiPartBody(
      'profile',
      new ValidationPipe({ validateCustomDecorators: true }),
    )
    createUserDto: CreateUserDto,
  ) {
    const user = await this.usersService.createUser(createUserDto);
    return user;
  }

  @Delete(':id')
  usersRemove(@Param('id') id: string) {
    return this.usersService.removeUser(+id);
  }

  @Patch(':id')
  @UseInterceptors(FileInterceptor('image'))
  async usersModify(
    @Param('id') userId: string,
    @MultiPartBody('profile') body: UpdateUsersDto,
    @UploadedFile() file: Express.Multer.File,
  ) {
    await this.usersService.updateUserById(userId, body, file);
  }
}
