import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';
import { provideHttpClient } from '@angular/common/http';
import { TestBed } from '@angular/core/testing';

import { AppEnvironment } from '../config/app-environment';
import { ApiClientService, ApiRequestError } from './api-client.service';

describe('ApiClientService', () => {
  let service: ApiClientService;
  let httpMock: HttpTestingController;

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [provideHttpClient(), provideHttpClientTesting()],
    });

    service = TestBed.inject(ApiClientService);
    httpMock = TestBed.inject(HttpTestingController);
  });

  afterEach(() => {
    httpMock.verify();
  });

  it('classifies HTTP 0 as a network failure and keeps attempt details', async () => {
    const requestPromise = service.postToCandidates({
      paths: ['/api/users/login'],
      body: { email: 'demo@mail.com', password: '1234' },
    });

    for (const [index, baseUrl] of AppEnvironment.baseUrls.entries()) {
      const request = httpMock.expectOne(`${baseUrl}/api/users/login`);
      request.error(new ProgressEvent('error'), { status: 0, statusText: 'Unknown Error' });

      if (index < AppEnvironment.baseUrls.length - 1) {
        await Promise.resolve();
      }
    }

    await requestPromise.then(
      () => fail('Expected a network error'),
      (error: unknown) => {
        expect(error instanceof ApiRequestError).toBeTrue();
        expect((error as ApiRequestError).kind).toBe('network');
        expect((error as ApiRequestError).attempts.length).toBe(AppEnvironment.baseUrls.length);
      },
    );
  });

  it('stops on 401 and preserves an auth rejection message', async () => {
    const requestPromise = service.postToCandidates({
      paths: ['/api/users/login'],
      body: { email: 'demo@mail.com', password: 'wrong-password' },
    });

    const request = httpMock.expectOne(`${AppEnvironment.baseUrls[0]}/api/users/login`);
    request.flush({ message: 'Credenciales inválidas.' }, { status: 401, statusText: 'Unauthorized' });

    await requestPromise.then(
      () => fail('Expected an auth rejection'),
      (error: unknown) => {
        expect(error instanceof ApiRequestError).toBeTrue();
        expect((error as ApiRequestError).kind).toBe('auth');
        expect((error as ApiRequestError).message).toContain('Credenciales inválidas');
      },
    );
  });
});
